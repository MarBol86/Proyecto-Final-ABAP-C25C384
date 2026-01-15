CLASS zcl_insert_values_mb DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_insert_values_mb IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DELETE FROM zdt_status_mb.
    INSERT zdt_status_mb  FROM TABLE @( VALUE #(
    ( status_code = 'OP' status_description = 'Open' )
    ( status_code = 'IP' status_description = 'In Progress' )
    ( status_code = 'PE' status_description = 'Pending' )
    ( status_code = 'CO' status_description = 'Completed' )
    ( status_code = 'CL' status_description = 'Closed' )
    ( status_code = 'CN' status_description = 'Canceled' ) ) ).

    out->write( |Status.... { sy-dbcnt } rows inserted| ).

    DELETE FROM zdt_priority_mb.
    INSERT zdt_priority_mb  FROM TABLE @( VALUE #(
    ( priority_code = 'H' priority_description = 'High' )
    ( priority_code = 'M' priority_description = 'Medium' )
    ( priority_code = 'L' priority_description = 'Low' ) ) ).

    out->write( |Priority.... { sy-dbcnt } rows inserted| ).


  ENDMETHOD.
ENDCLASS.
