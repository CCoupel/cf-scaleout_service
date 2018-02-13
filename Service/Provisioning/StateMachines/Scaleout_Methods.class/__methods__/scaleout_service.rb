#
# Description: <Grab all elments from provisioning and dialog to launch an identical VM provisionning>
#

$evm.log("info", "CC-Add_VM starting")
$evm.log(:info, "CC- called from #{$evm.root['vmdb_object_type']}")

vms=nil
svc=nil

case $evm.root['vmdb_object_type']
  when "vm"
    vms=$evm.root["vm"]
    svc=vms.direct_service
  when "service"
    svc=$evm.root["service"]
    vms=svc.direct_vms.first
  when "miq_provision"
    whocallme=$evm.root["miq_provision"]
    exit MIQ_ERROR
end

orig_svc=svc
  svc=orig_svc.parent_service if svc.service_template.nil?

$evm.log("info", "CC- Service: ===========================================")
$evm.log("info", "\tCC- #{svc.inspect}")

if svc.error_retiring? | svc.retired? | svc.retiring?
      $evm.log(:info, "CC- Error Service is #{svc.retirement_state}.")
      $evm.create_notification(:level => "warning", :message => "service #{svc.name} is #{svc.retirement_state}, can not be extended.")
      $evm.root['ae_result'] = 'error'
      exit MIQ_ERROR
end
  
dialog_options=Hash.new
svc.options[:dialog].each { |k,v| dialog_options[k.to_s.gsub(/.*::dialog_/,'').gsub(/^dialog_/, '')] = v.to_s }

$evm.create_notification(:level=>"success", :message => "extending service #{svc.name}")

dialog_options["number_of_vms"]="1"
dialog_options["option_0_number_of_vms"]="1"
dialog_options["vm_name"]="changeme"
dialog_options["option_0_service_name"]="scale-out"

dialog_options.sort.each { |k, v| $evm.log("info", "\t\tCC-dialog_options #{k}: #{v}") }

request =$evm.execute('create_service_provision_request', svc.service_template, dialog_options)

$evm.set_state_var('request_id', request.id)
$evm.log("info", "CC- request_id ===========================================")
$evm.log("info", "\tCC- #{request.inspect}")
request.attributes.sort.each { |k, v| $evm.log("info", "\t\tCC- #{k}: #{v}") }
