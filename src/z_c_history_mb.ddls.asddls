@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Inc. History | Consumption'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.semanticKey:[ 'HisId' ]
define view entity Z_C_HISTORY_MB
  as projection on Z_R_HISTORY_MB
{
  key HisUUID,
      IncUUID,
      HisId,
      PreviousStatus,
      NewStatus,
      Text,
      LocalLastChangedAt,
      LastChangedAt,
      /* Associations */
      _Incidents : redirected to parent Z_C_INCIDENTS_MB
}
