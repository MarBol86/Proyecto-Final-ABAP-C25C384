@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Inc. History | Consumption'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.semanticKey:[ 'HisId' ]
define view entity Z_C_HISTORY_MB
  as projection on z_R_history_mB
{
  key HisUUID,
      IncUUID,
      HisId,
      PreviousStatus,
      NewStatus,
      Text,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      /* Associations */
      _Incidents : redirected to parent Z_C_INCIDENTS_MB
}
