--
--  Variable list for the properties
--
instrument = nil

selector = {}
selector.instrument = {}
selector.instrument.chain = {}
selector.instrument.name = {}
selector.instrument.track = {}
selector.instrument.indevice = {}
selector.instrument.inchannel = {}
selector.instrument.outdevice = {}
selector.instrument.outchannel = {}
indevices = {}
outdevices = {}
indevice_value = 1
outdevice_value = 1
instrument_amount = 0

solo_instrument = nil
master = {}
master.device = ""
master.channel = 0
master.devices = {}
master.change = false

NO_DEVICE = "Master"
devices = {}
tracks = {0,1}


multi_track = false
track_edit_text = "Multitrack edit"
--track_edit_text = "Propagate changes"
propagation_info= "When chain-recording, when you edit one cell in one track\n"..
                "the adjustment also applies to the other linked tracks"
--propagation_info= "When chain-recording, when you edit one of the chained tracks\n"..
--                "push this button to propagate the contents to the other tracks\n"..
--                "Warning:this may include automation when present and possible"

midi_in_gui = false
midi_out_gui = false


selector_dialog = nil
start_instrument = 1
visible_range = 10
created_range = nil
--the below two variables exist as states to prevent notifier feedbacks
changed_from_renoise = nil
scrolled = nil

clock = os.clock()

--This is for the automatic track change propagation, trying to perform some educated monitoring here.
change_queue = {}
change_queue.pattern = {}
change_queue.track = {}
change_queue.line = {}

preferences = nil


tool_name = "Midi Management Console"
vb = nil



