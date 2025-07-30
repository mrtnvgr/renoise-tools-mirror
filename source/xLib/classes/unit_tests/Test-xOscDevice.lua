--[[ 

  Testcase for xOscDevice

--]]

_xlib_tests:insert({
name = "xOscDevice",
fn = function()

  print(">>> xOscDevice: starting unit-test...")

  require (_clibroot.."cDocument")
  require (_xlibroot.."xOscDevice")

  -- construct from scratch
  local device = xOscDevice{ 
    name = "My TestDevice",
    prefix = "/test",
    address = "127.0.0.1",
    port_in = 8000,
    port_out = 8080,
  }

  print(device)

  assert(device.name,"My TestDevice")
  assert(device.prefix,"/test")
  assert(device.address,"127.0.0.1")
  assert(device.port_in,8000)
  assert(device.port_out,8080)

  device.name = "My TestDevice2"
  assert(device.name,"My TestDevice2")

  device.prefix = "/test2"
  assert(device.prefix,"/test2")

  device.address = "127.0.0.2"
  assert(device.address,"127.0.0.2")

  device.port_in = 8002
  assert(device.port_in,8002)

  device.port_out = 8082
  assert(device.port_out,8082)

  -- test export (cDocument) --
  --[[
  assert(type(device:serialize()) == "table")
  assert(type(device:export()) == "DocumentNode")

  local serialized = device:serialize()
  assert(serialized.name,"My TestDevice2")
  assert(serialized.prefix,"/test2")
  assert(serialized.address,"127.0.0.2")
  assert(serialized.port_in,8002)
  assert(serialized.port_out,8082)
  ]]


  print(">>> xOscDevice: OK - passed all tests")

end
})
