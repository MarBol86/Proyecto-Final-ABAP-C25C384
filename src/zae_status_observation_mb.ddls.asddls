@EndUserText.label: 'Abstract Entity | Status - Observation'
define abstract entity ZAE_STATUS_OBSERVATION_MB
{
  @Consumption.valueHelpDefinition: [{
     entity : { name: 'ZDD_STATUS_MB_VH',
              element: 'status_code'  },
     useForValidation: true  }]
  @EndUserText.label:'Change Status'
  newstatus : zde_statusp_mb;
  @EndUserText.label:'Add Observation Text'
  newtext   : abap.char(80);

}
