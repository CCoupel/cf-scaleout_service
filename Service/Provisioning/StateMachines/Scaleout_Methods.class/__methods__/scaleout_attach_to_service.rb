#
# Description: <Method description here>
#

prov=$evm.root["miq_provision"]

  request_id=$evm.get_state_var('request_id')

  request=$evm.vmdb('ServiceTemplateProvisionRequest').find_by_id(request_id)
  
  request_state = request.request_state.downcase
  $evm.log(:info, "\tCC- request_status: #{request_state}/#{request.status} description: #{request.message} .")

  svc=$evm.root['service']

  $evm.log(:info, "CC- temp service #{request.message} has #{request.miq_request_tasks.count} tasks")
  request.miq_request_tasks.each do |task| 
    $evm.log(:info, "\tCC- temp service tasks (#{task.destination_type}): #{task.destination.name rescue nil}")
    unless task.destination.nil?
      $evm.log(:info, "\tCC- checking #{task.destination.name rescue nil} as service (#{task.destination_type.downcase rescue nil})")
      if (task.destination_type.downcase rescue nil)=="service" 
#        if task.destination.parent_service.nil?
#          $evm.log(:info, "\tCC- moving VMs from #{task.destination.name rescue nil} to #{task.destination.parent_service.name rescue "none"} to #{svc.name}")
          tmp_svc=task.destination
          tmp_svc.direct_vms.each do |vm|
            vm.remove_from_service
            vm.add_to_service(svc)
          end
 #       end
      end
    end
  end
