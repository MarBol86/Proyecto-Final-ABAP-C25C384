@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Inc. History | Interface'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z_I_HISTORY_MB as projection on Z_R_HISTORY_MB
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
    _Incidents : redirected to parent Z_I_INCIDENTS_MB
}
