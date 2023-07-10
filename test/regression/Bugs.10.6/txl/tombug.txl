
include "simulink.grm"
include "stateflow.grm"

function main
   replace [program]
        P [program]

   export MachineIds [repeat number]
        _
   export ChartIds [repeat number]
        _
   export StateIds [repeat number]
        _
   export DataIds [repeat number]
        _
   export FataIds [repeat number]
        _

   by
        P
          [getMachineIds]

end function

rule getMachineIds
   replace $ [id]
      ML [id]
   by
      ML
end rule

