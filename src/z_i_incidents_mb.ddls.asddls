@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Incidents | Interface Entity'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_I_INCIDENTS_MB
  provider contract transactional_interface
  as projection on Z_R_INCIDENTS_MB
{
  key IncUUID,
      IncidentId,
      Title,
      Description,
      Status,
      Priority,
      CreationDate,
      ChangedDate,
      LocalLastChangedAt,
      LastChangedAt,
      /* Associations */
      _Priority,
      _Status,
      _History: redirected to composition child Z_I_HISTORY_MB
}
