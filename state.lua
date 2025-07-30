---@alias RendererType
---| "cycle"
---| "raw"
-- ---| "mapped"

RendererType = {}
class("RendererType")
---@type fun(): RendererType[]
function RendererType.keys()
	return { "cycle", "raw" }
end

---@type fun(i:integer): RendererType
function RendererType.from_integer(i)
	return RendererType.keys()[math.min(math.max(1, i), #RendererType.keys())]
end

---@type fun(s: string): integer
function RendererType.to_integer(s)
	local i = table.find(RendererType.keys(), s)
	if i then
		---@diagnostic disable-next-line
		return i
	else
		return 1
	end
end

---@class Renderer
---@field render fun(song: renoise.Song, text: string): string[]
---@field copy NoteColumnMapper

---@class CyclerTrackState : renoise.Document.DocumentNode
---@field valid renoise.Document.ObservableBoolean
---@field track_index renoise.Document.ObservableNumber
---@field instrument renoise.Document.ObservableNumber
---@field renderer_type renoise.Document.ObservableString
---@field script renoise.Document.ObservableString
---@field octave renoise.Document.ObservableString

CyclerTrackState = {}
class("CyclerTrackState")(renoise.Document.DocumentNode)
function CyclerTrackState:__init()
	renoise.Document.DocumentNode.__init(self)
	self:add_properties({
		valid = renoise.Document.ObservableBoolean(),
		track_index = renoise.Document.ObservableNumber(),
		instrument = renoise.Document.ObservableNumber(),
		renderer_type = renoise.Document.ObservableString(),
		script = renoise.Document.ObservableString(),
		octave = renoise.Document.ObservableString(),
	})
end

---@type fun(song: renoise.Song, track_index: integer): CyclerTrackState
function CyclerTrackState.from_song_track(song, track_index)
	---@type CyclerTrackState
	local t = CyclerTrackState()
	t.valid.value = song:track(track_index).type == renoise.Track.TRACK_TYPE_SEQUENCER
	t.track_index.value = track_index
	t.instrument.value = 0
	t.renderer_type.value = RendererType.from_integer(1)
	t.script.value = ""
	t.octave.value = ""
	return t
end

---@class CyclerPatternState : renoise.Document.DocumentNode
---@field tracks renoise.Document.DocumentList
---@field track fun(self: CyclerPatternState, song: renoise.Song, index: integer): CyclerTrackState

CyclerPatternState = {}
class("CyclerPatternState")(renoise.Document.DocumentNode)
function CyclerPatternState:__init()
	renoise.Document.DocumentNode.__init(self)
	self:add_property("tracks", renoise.Document.DocumentList())
end

---@type fun(song: renoise.Song): CyclerPatternState
function CyclerPatternState.from_song(song)
	---@type CyclerPatternState
	local p = CyclerPatternState()
	for i = 1, #song.tracks do
		---@type CyclerTrackState
		local t = CyclerTrackState.from_song_track(song, i)
		p.tracks:insert(i, t)
	end
	return p
end

---@type fun(self: CyclerPatternState, song: renoise.Song, index: integer): CyclerTrackState
function CyclerPatternState:track(song, index)
	if index <= 0 then
		index = 1
	end
	if index > #self.tracks then
		self.tracks:insert(#self.tracks + 1, CyclerTrackState.from_song_track(song, index))
	end

	return self.tracks:property(index)
end

---@class CyclerState : renoise.Document.DocumentNode
---@field patterns renoise.Document.DocumentList
---@field pattern fun(self: CyclerState, song: renoise.Song, index: integer): CyclerPatternState
---@field pattern_track fun(self: CyclerState, song: renoise.Song, pattern_index: integer, track_index: integer): CyclerTrackState

CyclerState = {}
class("CyclerState")(renoise.Document.DocumentNode)
function CyclerState:__init()
	renoise.Document.DocumentNode.__init(self)
	self:add_property("patterns", renoise.Document.DocumentList())
end

---@type fun(self: CyclerState, song: renoise.Song, index: integer): CyclerPatternState
function CyclerState:pattern(song, index)
	if index <= 0 then
		index = 1
	end
	if index > #self.patterns then
		self.patterns:insert(#self.patterns + 1, CyclerPatternState.from_song(song))
	end

	return self.patterns:property(index)
end

---@type fun(song: renoise.Song): CyclerState
function CyclerState.from_song(song)
	---@type CyclerState
	local s = CyclerState()
	for i = 1, #song.patterns do
		---@type CyclerPatternState
		local p = CyclerPatternState.from_song(song)
		s.patterns:insert(i, p)
	end
	return s
end

---@type fun(self: CyclerState, song: renoise.Song, pattern_index: integer, track_index: integer): CyclerTrackState
function CyclerState:pattern_track(song, pattern_index, track_index)
	local p = self:pattern(song, pattern_index)
	local t = p:track(song, track_index)
	return t
end
