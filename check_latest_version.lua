require "check_latest_version_gui"
require "renoise.http"

--------------------------------------------------------------------------------
-- variables
--------------------------------------------------------------------------------
version_number = nil
release_date = nil
download_url = nil

--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

local function success(data, text_status, xml_http_request)    
    
    for k, v in ipairs(data['ChildNodes']) do
      local node_name = v['Name']
      
      if node_name ~= nil then
        if node_name == 'latestversion' then version_number = v['Value']
        elseif node_name == 'latestversionurl' then download_url = v['Value']
        elseif node_name == 'latestversiondate' then release_date = v['Value']
        end
      end
          
    end
    
    show_latestversion_dialog()
        
end

function check_latest_version()
  
  local data = {}
  
  HTTP:get(XRNS2XMOD_VERSION_INFO_URL, data, success, 'XML')
  
  --success('', '', '')
  
  
  
end


