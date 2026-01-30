CLASS lhc_Incidents DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF mcs_status,
        open        TYPE c LENGTH 2 VALUE 'OP',
        In_Progress TYPE c LENGTH 2 VALUE 'IP',
        Pending     TYPE c LENGTH 2 VALUE 'PE',
        Completed   TYPE c LENGTH 2 VALUE 'CO',
        Closed      TYPE c LENGTH 2 VALUE 'CL',
        Canceled    TYPE c LENGTH 2 VALUE 'CN',
      END OF mcs_status,
      BEGIN OF mcs_priority,
        high   TYPE c LENGTH 1 VALUE 'H',
        Medium TYPE c LENGTH 1 VALUE 'M',
        Low    TYPE c LENGTH 1 VALUE 'L',
      END OF mcs_priority.


    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Incidents RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Incidents RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Incidents RESULT result.

    METHODS changeStatus FOR MODIFY
      IMPORTING keys FOR ACTION Incidents~changeStatus RESULT result.

    METHODS setvalues FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Incidents~setvalues.

    METHODS createHistory FOR DETERMINE ON SAVE
      IMPORTING keys FOR Incidents~createHistory.
    METHODS validateMandatory FOR VALIDATE ON SAVE
      IMPORTING keys FOR Incidents~validateMandatory.

ENDCLASS.

CLASS lhc_Incidents IMPLEMENTATION.

  METHOD get_instance_features.

    "Read Entity
    READ ENTITIES OF z_r_incidents_mb IN LOCAL MODE
    ENTITY Incidents
    FIELDS ( IncidentId CreationDate Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(incidents)
    FAILED failed.

    "                                                "Puede ser creación o modificación
*    DELETE incidents WHERE IncidentId IS INITIAL OR %is_draft EQ if_abap_behv=>mk-off.

    CHECK incidents IS NOT INITIAL.

    SELECT FROM zdt_inct_mb AS ddbb
    INNER JOIN @incidents AS http_req ON ddbb~incident_id = http_req~IncidentId
    FIELDS ddbb~incident_id
    INTO TABLE @DATA(valid_ids).

    result = VALUE #( FOR incident IN incidents (
                                         %tky = incident-%tky
                                         %action-changeStatus = COND #( WHEN NOT line_exists( valid_ids[ incident_id = incident-IncidentId ] ) "Se chequea existencia DB
                                                                        OR incident-status = mcs_status-canceled
                                                                        OR incident-status = mcs_status-completed
                                                                        OR incident-status = mcs_status-closed
                                                                        THEN if_abap_behv=>fc-o-disabled
                                                                        ELSE if_abap_behv=>fc-o-enabled  )
    ) ) .



  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD changeStatus.

    DATA: history_for_create  TYPE TABLE FOR CREATE z_r_incidents_mb\_History,
          incident_for_update TYPE TABLE FOR UPDATE z_r_incidents_mb.

    "Read parent record
    READ ENTITIES OF z_r_incidents_mb IN LOCAL MODE
    ENTITY Incidents
    FIELDS ( IncUUID Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(incidents).

    LOOP AT incidents INTO DATA(incident).

      "Obtenemos parámetros de la entidad abstracta
      DATA(new_status) = keys[ KEY id %tky = incident-%tky ]-%param-newstatus.
      DATA(new_text)   = keys[ KEY id %tky = incident-%tky ]-%param-newtext.


      "Si el estado es PE no es posible modificarlo a CO o CL
      IF incident-Status = mcs_status-pending AND
      ( new_status =  mcs_status-completed OR new_status =  mcs_status-closed ).
        DATA(lv_error) = abap_true.
        "Bloqueamos la acción
        APPEND VALUE #( %tky = incident-%tky ) TO failed-incidents.
        "Mensaje
        APPEND VALUE #( %tky = incident-%tky
                        %msg = NEW /dmo/cm_flight_messages( textid = zcm_incidents_mb=>invalid_status
                                                                   severity = if_abap_behv_message=>severity-error )
                        %op-%action-changeStatus = if_abap_behv=>mk-on
                                                                    ) TO reported-incidents .

      ENDIF.

      " Get History ID
      SELECT SINGLE FROM zdt_inct_h_mb
      FIELDS MAX( his_id )
      WHERE  inc_uuid = @incident-IncUUID
      INTO @DATA(lv_max_his_id).


      APPEND VALUE #(
                   %tky = incident-%tky
                   %target  = VALUE #( ( %cid           = |HIST_{ sy-tabix }|
                                         incuuid        = incident-IncUUID
                                         hisid          = lv_max_his_id + 1
                                         previousstatus = incident-Status
                                         newstatus      = new_status
                                         text           = new_text  ) )
                                     ) TO history_for_create.

      APPEND VALUE #( %tky = incident-%tky
                     status = new_status
                     changeddate = cl_abap_context_info=>get_system_date(  ) ) TO incident_for_update.



    ENDLOOP.

    CHECK lv_error IS INITIAL.

    "Actualiza DB
    MODIFY ENTITIES OF z_r_incidents_mb IN LOCAL MODE
    ENTITY Incidents
    UPDATE FIELDS ( Status ChangedDate )
    WITH incident_for_update.

    MODIFY ENTITIES OF z_r_incidents_mb IN LOCAL MODE
    ENTITY Incidents
    CREATE BY \_History
    FIELDS ( incuuid hisid previousstatus newstatus text )
    WITH history_for_create
    MAPPED mapped
    REPORTED DATA(ls_reported)
    FAILED failed .


    "Informamos los cambios
    READ ENTITIES OF z_r_incidents_mb IN LOCAL MODE
     ENTITY Incidents
     ALL FIELDS
     WITH CORRESPONDING #( keys )
     RESULT DATA(incidents_new_status).

    result = VALUE #( FOR incident_new IN incidents_new_status ( %tky =  incident_new-%tky
                                                                 %param = incident_new ) ) .


  ENDMETHOD.

  METHOD setvalues.

    "Read Entity
    READ ENTITIES OF z_r_incidents_mb IN LOCAL MODE
    ENTITY Incidents
    FIELDS ( IncidentId CreationDate Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(incidents).

    DELETE incidents WHERE IncidentId IS NOT INITIAL.

    CHECK incidents IS NOT INITIAL.

    " Get Incidet ID
    SELECT SINGLE FROM zdt_inct_mb
    FIELDS MAX( Incident_Id )
    INTO @DATA(lv_max_incident_id).

    " Contemplamos varios registros.
    MODIFY ENTITIES OF z_r_incidents_mb IN LOCAL MODE
    ENTITY Incidents
    UPDATE FIELDS ( IncidentId CreationDate Status )
    WITH VALUE #( FOR incident IN incidents INDEX INTO i
                         ( %tky = incident-%tky
                         IncidentId = lv_max_incident_id + i
                         CreationDate = cl_abap_context_info=>get_system_date( )
                         Status = mcs_status-open )  ).

  ENDMETHOD.

  METHOD createHistory.

    DATA: history_for_create TYPE TABLE FOR CREATE z_r_incidents_mb\_History.

    "Read parent record
    READ ENTITIES OF z_r_incidents_mb IN LOCAL MODE
    ENTITY Incidents
    FIELDS ( IncUUID Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(incidents).


    "Create child records
    LOOP AT incidents INTO DATA(incident).

      " Get Incidet ID
      SELECT SINGLE FROM zdt_inct_mb
      FIELDS MAX( Incident_Id )
      WHERE  inc_uuid = @incident-IncUUID
      INTO @DATA(lv_max_his_id).

      APPEND VALUE #(
                   %tky = incident-%tky
                   %target  = VALUE #( ( %cid = |HIST_{ sy-tabix }|
                                         incuuid = incident-IncUUID
                                         hisid = lv_max_his_id + 1
                                         newstatus = incident-Status
                                         text = 'First Incident'  ) )
                                     ) TO history_for_create.

    ENDLOOP.

    "No se hace MODIFY ENTITIES sobre la entidad hija directamente
    "Siempre se crea el hijo a través del padre usando el CREATE BY _Hijo
    MODIFY ENTITIES OF z_r_incidents_mb IN LOCAL MODE
    ENTITY Incidents
      CREATE BY \_History
      FIELDS ( incuuid hisid previousstatus newstatus text ) WITH history_for_create
    MAPPED DATA(ls_mapped)
    REPORTED DATA(ls_reported)
    FAILED DATA(ls_failed).

  ENDMETHOD.

  METHOD validateMandatory.

    "Read Entity
    READ ENTITIES OF z_r_incidents_mb IN LOCAL MODE
    ENTITY Incidents
    FIELDS ( title description priority )
    WITH CORRESPONDING #( keys )
    RESULT DATA(incidents).

    LOOP AT incidents INTO DATA(incident).

* Title Mandatory
      IF incident-Title IS INITIAL.
        APPEND VALUE #( %tky = incident-%tky ) TO failed-incidents.
        APPEND VALUE #( %tky = incident-%tky
                        %state_area = 'MANDATORY'
                               %msg = NEW /dmo/cm_flight_messages( textid = zcm_incidents_mb=>enter_title
                                                                 severity = if_abap_behv_message=>severity-error )
                  %element-Title = if_abap_behv=>mk-on ) TO reported-incidents.
      ENDIF.

* Description Mandatory
      IF incident-Description IS INITIAL.
        APPEND VALUE #( %tky = incident-%tky ) TO failed-incidents.
        APPEND VALUE #( %tky = incident-%tky
                        %state_area = 'MANDATORY'
                               %msg = NEW /dmo/cm_flight_messages( textid = zcm_incidents_mb=>enter_Description
                                                                 severity = if_abap_behv_message=>severity-error )
                  %element-Description = if_abap_behv=>mk-on ) TO reported-incidents.
      ENDIF.

* Priority Mandatory with determinate values
      IF incident-Priority IS INITIAL.
        APPEND VALUE #( %tky = incident-%tky ) TO failed-incidents.
        APPEND VALUE #( %tky = incident-%tky
                        %state_area = 'MANDATORY'
                               %msg = NEW /dmo/cm_flight_messages( textid = zcm_incidents_mb=>enter_Priority
                                                                 severity = if_abap_behv_message=>severity-error )
                  %element-Priority = if_abap_behv=>mk-on ) TO reported-incidents.

      ELSE.
        "¿Value valid?
        SELECT SINGLE FROM zdt_priority_mb
        FIELDS priority_code
        WHERE priority_code = @incident-Priority
        INTO @DATA(priority).
        IF sy-subrc NE 0.
          APPEND VALUE #( %tky = incident-%tky ) TO failed-incidents.
          APPEND VALUE #( %tky = incident-%tky
                          %state_area = 'MANDATORY'
                                 %msg = NEW /dmo/cm_flight_messages( textid = zcm_incidents_mb=>invalid_priority
                                                                   severity = if_abap_behv_message=>severity-error )
                    %element-Priority = if_abap_behv=>mk-on ) TO reported-incidents.
        ENDIF.

      ENDIF.

    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
