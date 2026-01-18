@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Incidents | Consumotion Entity'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity Z_C_INCIDENTS_MB
  provider contract transactional_query
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
      _History: redirected to composition child Z_C_HISTORY_MB
}
