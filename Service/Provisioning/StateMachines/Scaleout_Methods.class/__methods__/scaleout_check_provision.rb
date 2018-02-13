#
# Description: <Wait for the new VM/service to be created>
#

begin
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
      case (task.destination_type.downcase rescue nil)
      when "service" 
        if task.destination.parent_service.nil?
          $evm.log(:info, "\tCC- setting #{task.destination.name rescue nil} as child from #{task.destination.parent_service.name rescue "none"} to #{svc.name}")
          task.destination.parent_service=svc 
        end
      when "vm"

         
      end
    end
  end
  
  
  case request_state
    when 'error'
      $evm.log(:info, "CC- Resource is in ERROR.")
      $evm.root['ae_result'] = 'error'
    when 'finished'
      if request.status.downcase == "error"
      then
        $evm.log(:info, "CC- Resource is provisioned but with error. Exiting.")
        $evm.root['ae_result'] = 'error'
      else
        $evm.log(:info, "CC- Resource is provisioned. Exiting.")
        $evm.root['ae_result'] = 'ok'
      end
    else
      $evm.log(:info, "CC- Resource is #{request_state}. Retrying.")
      $evm.root['ae_result'] = 'retry'
      $evm.root['ae_retry_interval'] = "1.minute"
  end
end
