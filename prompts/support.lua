--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Prompt Support Code
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Enums
--------------------------------------------------------------------------------
PROMPT_BASE         = 1
PROMPT_INST_IDX     = 2
PROMPT_TRACK_IDX    = 3
PROMPT_SEQ_IDX      = 4
PROMPT_NOTECOL_IDX  = 5
PROMPT_PATT_LEN     = 6
PROMPT_NOTE_DELAY   = 7
PROMPT_NOTE_VOLUME  = 8
PROMPT_NOTE_PANNING = 9
PROMPT_SMAP_NOTE    = 10
PROMPT_SMAP_VEL     = 11
PROMPT_SAMP_VPN     = 12
PROMPT_SAMP_TTI     = 13
PROMPT_BPM          = 14
PROMPT_TRACK_OUTDEL = 15
PROMPT_SAMP_REC     = 16
PROMPT_SAMP_LOOP    = 17
PROMPT_SAMP_SLICE   = 18
PROMPT_SAMP_AUTOCHOP= 19
PROMPT_PAD_SCALE    = 20



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function set_prompt(mode)
  if prompt then
    if prompt.prompt == mode then
      return
    else
      prompt:ok()
    end
  end

  if mode == PROMPT_INST_IDX then
    prompt = InstIndexPrompt()
  elseif mode == PROMPT_TRACK_IDX then
    prompt = TrackIndexPrompt()
  elseif mode == PROMPT_SEQ_IDX then
    prompt = SequencerIndexPrompt()
  elseif mode == PROMPT_NOTECOL_IDX then
    prompt = NoteColIndexPrompt()
  elseif mode == PROMPT_PATT_LEN then
    prompt = PattLenPrompt()
  elseif mode == PROMPT_NOTE_DELAY then
    prompt = NoteDelayPrompt()
  elseif mode == PROMPT_NOTE_VOLUME then
    prompt = NoteVolumePrompt()
  elseif mode == PROMPT_NOTE_PANNING then
    prompt = NotePanningPrompt()
  elseif mode == PROMPT_SMAP_NOTE then
    prompt = SampMapNotePrompt()
  elseif mode == PROMPT_SMAP_VEL then
    prompt = SampMapVelPrompt()
  elseif mode == PROMPT_SAMP_VPN then
    prompt = SampVpnPrompt()
  elseif mode == PROMPT_SAMP_TTI then
    prompt = SampTtiPrompt()
  elseif mode == PROMPT_BPM then
    prompt = BpmPrompt()
  elseif mode == PROMPT_TRACK_OUTDEL then
    prompt = TrackOutputPrompt()
  elseif mode == PROMPT_SAMP_REC then
    prompt = SampRecPrompt()
  elseif mode == PROMPT_SAMP_LOOP then
    prompt = SampLoopPrompt()
  elseif mode == PROMPT_SAMP_SLICE then
    prompt = SampSlicePrompt()
  elseif mode == PROMPT_SAMP_AUTOCHOP then
    prompt = SampAutoChopPrompt()
  elseif mode == PROMPT_PAD_SCALE then
    prompt = PadScalePrompt()
  end
end
