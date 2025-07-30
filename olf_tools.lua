
function getSelectedUsableTrackIndex()
  local patt = renoise.song().selected_pattern;
  local cIndex = renoise.song().selected_track_index;
  
  local numTracks = table.getn( renoise.song().tracks );
  local index2 = 1;
  for i=1, numTracks do
    if( i == cIndex ) then
      return index2;
    end     
    if( renoise.song().tracks[i].type == renoise.Track.TRACK_TYPE_SEQUENCER ) then
      index2 = index2 + 1;
    end
  end  
  return 0;
end

function iif( cond, ifTrue, ifFalse)
  if( cond ) then
    return ifTrue;
  else  
    return ifFalse;
  end
end

function openURL(url)
  renoise.app():open_url(url);
  --[[
  local sCmd = "";
  if os.platform() == 'WINDOWS' then -- windows
    sCmd = string.format('start "" "%s"', url); 
  elseif (os.platform() == "MACINTOSH") then   
    sCmd = string.format('open "%s"', url);
  elseif ( os.platform() == "LINUX" ) then
    sCmd = string.format('xdg-open "%s"', url);
  end
  if( sCmd ~= "" ) then
    os.execute(sCmd);
  end]]
end

function utf8length(str) 
  local charCount = 0;
  for i = 1, #str do
    local cb = string.byte(str:sub(i, i));
    if( bit.band(cb, 0xc0) ~= 0x80 ) then
      charCount = charCount + 1
    end
  end --end for
  return charCount; 
end

function addValueToEachElement(arr, iValToAdd)
  for arrPos=1, table.getn(arr) do
    arr[arrPos] = arr[arrPos] + (iValToAdd - 1); 
  end
  return arr;
end

function getNoteIndexes(noteNameArr)
  local arrBack = {}
  local foundNoteIndex = 0
  local i=1
  for i=1, table.getn(noteNameArr) do
    foundNoteIndex = getNoteIndex( noteNameArr[i] )
    if foundNoteIndex ~= 0 then
      arrBack[i] = foundNoteIndex
    end
  end
  return arrBack
end

function getNoteIndexesTransposed(noteNameArr, transposedTo)
  local transposeBy = getNoteIndex(transposedTo) - 1;
  local arrBack = {};
  local foundNoteIndex = 0;
  local i=1;
  for i=1, table.getn(noteNameArr) do
    foundNoteIndex = getNoteIndex( noteNameArr[i] );
    if foundNoteIndex ~= 0 then
      arrBack[i] = foundNoteIndex + transposeBy;
    end
  end
  return arrBack;
end

function getNoteIndex(noteName)
  local npl = {"C","C#","D","D#","E","F","F#","G","G#","A","A#","B","C2","C#2","D2","D#2","E2","F2","F#2","G2","G#2","A2","A#2","B2"};

  local i=1;
  for i=1, table.getn(npl) do
    if npl[i] == noteName then
      return i;
    end
  end
  return 0;
end

