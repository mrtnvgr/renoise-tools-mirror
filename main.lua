require "olf_tools"

_mainForm = nil;
_ctlMargin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN;
_guiUnit = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT;

LAST_SELECTED_TRACK = 1;
LAST_SELECTED_INSTRUMENT = 1;
LAST_SELECTED_ROOT_OCTAVE = 3;
LAST_SELECTED_BEGIN_NOTE = 1;
LAST_LOCKED_SCALE = 1;
LAST_SHOULD_ADD_BASS_NOTE = false;
LAST_SHOULD_MOVE_HIGH_NOTE_DOWN = false;

vb = nil;

local _selChordPerLines = {2,1,3,1,4,1,5,1};




function show_gui()
  vb = renoise.ViewBuilder();
  
  local patt = renoise.song().selected_pattern;
  
  LAST_SELECTED_INSTRUMENT = renoise.song().selected_instrument_index;
  LAST_SELECTED_TRACK = getSelectedUsableTrackIndex(); 
  
  
  local title = "Chord Progression Generator";
  
  local currTrack = patt:track( LAST_SELECTED_TRACK );
  local numLines = patt.number_of_lines;
  
  local innerWidth = (_guiUnit*18) - (_ctlMargin*4);
  local trackNameList = {};
  local numTracks = table.getn( renoise.song().tracks );
  
  for i=1, numTracks do
    local trackRef = renoise.song().tracks[i];
    
    local trackType = trackRef.type;
    local trackName = trackRef.name;
    
    if trackType == renoise.Track.TRACK_TYPE_SEQUENCER then    
      table.insert(trackNameList, i .. ") " .. trackName);
    end    
  end
  
  local instrumentList = {};
  local numInstruments = table.getn( renoise.song().instruments );
  for i=1, numInstruments do
    local instRef = renoise.song().instruments[i];
    table.insert( instrumentList, string.format("%02X", i - 1) .. ' '.. instRef.name );
  end

  local chordChooser     = {" - ", "Chord 1", "Chord 2", "Chord 3", "Chord 4", "Chord 5", "Chord 6", "Chord 7", "Chord 8"};
  local chordChoosersGui = {};
  for rad=1, 8 do
    chordChoosersGui[rad] = vb:horizontal_aligner {
        margin = _ctlMargin,          
        vb:text { id="txLine_"..rad, text = "", width = 0.4 * innerWidth },
        vb:popup {id = "chord"..rad, width = 0.5*innerWidth, items=chordChooser, tooltip = "Choose empty or chord for line", notifier=function(i) _selChordPerLines[rad]=i;end, value=_selChordPerLines[rad] }
    };
  end
  
  local dContent = vb:column{
      width = innerWidth+(_ctlMargin*4),
      margin = _ctlMargin,
      spacing = _guiUnit/2,

      vb:column{
        style = "panel",
        margin = _ctlMargin,
        width = "100%",
        
        vb:text{
          text = "Progression settings",
          font = "normal", 
          align = "center",
          width = "100%"
        },  
        vb:space{
          height = _guiUnit/3
        },
        vb:horizontal_aligner { -- 
          margin = _ctlMargin,
          
          vb:text {
            text = "First chord root note:",
            width = 0.4 * innerWidth
          },
           vb:popup{
            id = "initNote",
            width = 0.5*innerWidth,
            items = {"Random","C", "C#", "D", "D#", "E", "F", "F#","G","G#","A","A#","B"},
            value = LAST_SELECTED_BEGIN_NOTE,
            notifier = function (i)
              LAST_SELECTED_BEGIN_NOTE = i
            end  
          }
        },
        vb:horizontal_aligner { -- 
          margin = _ctlMargin,
          
          vb:text {
            text = "Mode:",
            width = 0.4 * innerWidth
          },
          vb:popup{
            id = "initScale",
            width = 0.5*innerWidth,
            items = {"Random","Maj", "Min", "Maj and Min", "Min and Dim"},
            value = LAST_LOCKED_SCALE,
            notifier = function (i)
              LAST_LOCKED_SCALE = i;
            end  
          }        
        },--end på horiz-alignern med bara min, maj eller random
        vb:horizontal_aligner { -- 
          margin = _ctlMargin,
          vb:text {
            text = "Last generated:",
            width = 0.4 * innerWidth
          },
          vb:multiline_textfield{
            id="rtbGenResult",
            font="mono",
            value="Chord 1: -    Chord 5: -\nChord 2: -    Chord 6: -\nChord 3: -    Chord 7: -\nChord 4: -    Chord 8: -",
            width= 0.5*innerWidth,
            active=false, 
            height=_guiUnit*3
          }          
        }
      },--end column
      vb:horizontal_aligner{
        margin = _ctlMargin,
        mode="right",
         
        vb:button {
            text = "1. Generate New progression",
            notifier = function() 
              generateProgression();
              vb.views['bWriteToTrack'].active=true
            end,
            width = 0.25 * innerWidth,
            tooltip = "Generate"
        }
      },      
      vb:column{
        style = "panel",
        margin = _ctlMargin,
        width = "100%",         
        
        vb:text{
          text = "Destination track and instrument",
          font="normal", 
          align = "center",
          width = "100%"
        },  
        vb:space{
          height = _guiUnit/3
        },
        vb:horizontal_aligner {
          margin = _ctlMargin,
      
          vb:text {
            text = "Destination track:",
            width = 0.4 * innerWidth
          },
          vb:popup{
            id = "selTrack",
            width = 0.5 * innerWidth,
            items = trackNameList,
            value = LAST_SELECTED_TRACK,
            notifier = function (i)
              LAST_SELECTED_TRACK = i;
              local strPrt = vb.views["selTrack"].items[i];
              local foundPos, foundPosEnd = string.find(strPrt, ")");
              if( foundPos ~= nil and foundPos > 0 ) then
                strPrt = string.sub(strPrt, 0, foundPos-1);
                LAST_SELECTED_TRACK = tonumber( strPrt );
              end
            end  
          }          
        }, 
        vb:horizontal_aligner { 
          margin = _ctlMargin,

          vb:text {
            text = "Instrument to use:",
            width = 0.4 * innerWidth
          },
          vb:popup{
            id = "selInstr",
            width = 0.5*innerWidth,
            items = instrumentList,
            value = LAST_SELECTED_INSTRUMENT,
            notifier = function (i)
              LAST_SELECTED_INSTRUMENT = i;
            end  
          }          
        },
        vb:horizontal_aligner { -- 
          margin = _ctlMargin,
          
          vb:text {
            text = "Root octave:",
            width = 0.4 * innerWidth
          },
          vb:valuebox {
            id = "rootOct",
            min=1,
            max=6,
            steps={1, 1},
            value = LAST_SELECTED_ROOT_OCTAVE,
            notifier =  function(x) 
              LAST_SELECTED_ROOT_OCTAVE = x;
            end,
            width = 0.5*innerWidth,
            tooltip = "Which initial octave is used"
          }
        },
        vb:horizontal_aligner {  
          margin = _ctlMargin,
          
          vb:text {
            text = "Add bass key (oct -1):",
            width = 0.4 * innerWidth
          },
          vb:checkbox{
            id = "cbAddLowOct",
            value = LAST_SHOULD_ADD_BASS_NOTE,
            notifier = function (isChecked)
              LAST_SHOULD_ADD_BASS_NOTE = isChecked;
            end  
          }    
        },
        vb:horizontal_aligner {  
          margin = _ctlMargin,
          
          vb:text {
            text = "High key down (oct -1):",
            width = 0.4 * innerWidth
          },
          vb:checkbox{
            id = "cbMoveHighDownOneOct",
            value = LAST_SHOULD_MOVE_HIGH_NOTE_DOWN,
            notifier = function (isChecked)
              LAST_SHOULD_MOVE_HIGH_NOTE_DOWN = isChecked;
            end  
          }    
        }--end last horiz-aligner..        
      },--end col
      vb:column{
        style = "panel",
        margin = _ctlMargin,
        width = "100%",         
        
        vb:text{
          text = "Chords track placement",
          font = "normal", 
          align = "center",
          width = "100%"
        },  
        vb:space{
          height = _guiUnit/3
        },
        chordChoosersGui[1],chordChoosersGui[2],chordChoosersGui[3],chordChoosersGui[4],
        chordChoosersGui[5],chordChoosersGui[6],chordChoosersGui[7],chordChoosersGui[8]
      },--end column..
      vb:horizontal_aligner{
        margin = _ctlMargin,          
        mode="right",
                
        vb:button {
          id="bWriteToTrack",
          text = "2. Write to track",
          notifier = function()
            generateContent();
          end,
          width = 0.25 * innerWidth,
          active=false,
          tooltip = "Go!"
        },
        vb:button {
          text = "Close",
          notifier = function() 
            if _mainForm.visible then
              _mainForm:close();
              removeObservables();
            end
          end,
          width = 0.25 * innerWidth,
          tooltip = "Closes the window"
        }          
      }, 
      vb:horizontal_aligner{
        margin = _ctlMargin,          
        mode="left",
        
        vb:button {
          id = "bDonate",
          text= "donate (Paypal)",
          notifier = function()
            openURL("https://www.paypal.com/donate/?hosted_button_id=7U5UGME2J73HS");
          end
        },
        vb:button {
          id = "bDonate2",
          text= "donate (Paypal.Me)",
          notifier = function()
            openURL("https://paypal.me/etromic");
          end
        },     
      }--sista horiz-alignern      
  }  
  
  _mainForm = renoise.app():show_custom_dialog(title, dContent );
  addObservables();    

  obs_pattern();
   
end --end function...

arrResultingChords = {}
arrProgressionObjs = {}

function generateProgression()
  local arrForChoosers = {" - "};
  arrProgressionObjs = getRandomChordsObjects(8);
  
  local strTemplate = "Chord 1: {1}  Chord 5: {5}\nChord 2: {2}  Chord 6: {6}\nChord 3: {3}  Chord 7: {7}\nChord 4: {4}  Chord 8: {8}";
  for i=1, table.getn(arrProgressionObjs) do
    local chordObj = arrProgressionObjs[i];
    local shortName = chordObj:getShortChordName();
    local numCharsInShortName = utf8length(shortName);
    if( numCharsInShortName == 2 ) then
      shortName = shortName .. " ";
    elseif( numCharsInShortName == 1) then
      shortName = shortName .. "  ";
    end
    
    strTemplate = string.gsub( strTemplate, "{"..i.."}", shortName ); 
    table.insert(arrForChoosers, "Chord " .. (i) .. "- " .. shortName .."(".. numCharsInShortName ..")");
  end
  
  vb.views["rtbGenResult"].text = strTemplate;
  for i=1, 8 do
    vb.views["chord" .. i].items = arrForChoosers;
  end
end


function generateContent()
  local rootOct = LAST_SELECTED_ROOT_OCTAVE * 12;
  local patt = renoise.song().selected_pattern;
  local currTrack = renoise.song().tracks[ getSelectedTrackIndex() ];
  local numLines = patt.number_of_lines;  
  
  patt:track( getSelectedTrackIndex() ):clear(); -- patterntrack
  currTrack.visible_note_columns = table.getn( arrProgressionObjs[1]:getChordAsInts() ) + iif(LAST_SHOULD_ADD_BASS_NOTE, 1, 0); -- track.
  
  for i=1, table.getn( arrProgressionObjs ) do
    arrResultingChords[i] = {};
    if( LAST_SHOULD_ADD_BASS_NOTE ) then
      arrResultingChords[i] = arrProgressionObjs[i]:getChordAsIntsAddNoteRelativeToFirstNote(-12);
      if( LAST_SHOULD_MOVE_HIGH_NOTE_DOWN ) then
        arrResultingChords[i][ table.getn(arrResultingChords[i])-1 ] = arrResultingChords[i][ table.getn(arrResultingChords[i])-1 ] - 12;
      end
    else
      arrResultingChords[i] = arrProgressionObjs[i]:getChordAsInts();
      if( LAST_SHOULD_MOVE_HIGH_NOTE_DOWN ) then
        arrResultingChords[i][ table.getn(arrResultingChords[i]) ] = arrResultingChords[i][ table.getn(arrResultingChords[i]) ] - 12; -- 
      end      
    end
    arrResultingChords[i] = addValueToEachElement(arrResultingChords[i], rootOct);
  end
    
  for j=1, table.getn(arrResultingChords) do
    
    for p=1, table.getn(_selChordPerLines) do

      local linePos = ((p-1)*(numLines / 8)) + 1;

      if( j == _selChordPerLines[p]-1 ) then
        
        for k=1, table.getn(arrResultingChords[j]) do 
          
          local singleNote = arrResultingChords[j][k];
          setNoteOnLineInColumn(singleNote, linePos, k);
          
        end--for k        
      end--if _selChordPerLines
    end--for p ..
  
  end -- end for j=1 ... 
  
end -- end function

function getSelectedTrackIndex()  
  local strPrt = vb.views["selTrack"].items[ vb.views["selTrack"].value ];
  local foundPos, foundPosEnd = string.find(strPrt, ")");
  if( foundPos ~= nil and foundPos > 0 ) then
    strPrt = string.sub(strPrt, 0, foundPos-1);
    return tonumber( strPrt );
  end
  return 0;
end

function setNoteOnLineInColumn(note, line, col)
  local patt = renoise.song().selected_pattern;
  local currTrack = patt:track( getSelectedTrackIndex() );
  local currentCell = currTrack:line(line):note_column(col);
  
  currentCell.note_value = note;
  currentCell.instrument_value = LAST_SELECTED_INSTRUMENT - 1;  
end

function obs_instrument()
  local instrumentList = {};
  local numInstruments = table.getn( renoise.song().instruments );
  for i=1, numInstruments do
    table.insert( instrumentList, string.format("%02X", i - 1) .. ' '.. renoise.song().instruments[i].name );
  end
  vb.views["selInstr"].items = instrumentList;
end
function obs_pattern()
  local oneEightsPattern = renoise.song().selected_pattern.number_of_lines / 8;
  for i=1, 8 do
    local lineNum = oneEightsPattern * (i-1);
    vb.views["txLine_"..i].text = "Line 0x" .. string.format("%02X", lineNum) .." (" .. string.format("%d", lineNum) .. "):";
  end  
end
function obs_tracks()
  local trackNameList = {};
  local numTracks = table.getn( renoise.song().tracks );
  for i=1, numTracks do
    local trackRef = renoise.song().tracks[i];
    
    if trackRef.type == renoise.Track.TRACK_TYPE_SEQUENCER then
      table.insert(trackNameList, i .. ") " .. trackRef.name);
    end    
  end
  vb.views["selTrack"].items = trackNameList;
end

function addObservables()
  if(not renoise.song().instruments_observable:has_notifier(obs_instrument) ) then
    renoise.song().instruments_observable:add_notifier(obs_instrument);
    renoise.song().selected_pattern_observable:add_notifier(obs_pattern);
    renoise.song().tracks_observable:add_notifier(obs_tracks);
  end  
end

function removeObservables()
  if(renoise.song().instruments_observable:has_notifier(obs_instrument) ) then
    renoise.song().instruments_observable:remove_notifier(obs_instrument);
    renoise.song().selected_pattern_observable:remove_notifier(obs_pattern);
    renoise.song().tracks_observable:remove_notifier(obs_tracks);
  end
end

NOTE_PIANO_LOCATION = {"C","C#","D","D#","E","F","F#","G","G#","A","A#","B","C2","C#2","D2","D#2","E2","F2","F#2","G2","G#2","A2","A#2","B2"}
CHORD_TYPE_MAJ = "maj";
CHORD_TYPE_MIN = "min";
CHORD_TYPE_DIM = "dim";

-- class start
class 'OlfChord'

  function OlfChord:__init(rootNote, chordType)
  
    self.initialRootNote = rootNote;
    self.chordType = chordType;
    self.chordNoteIndexes = {};
    self.chordNoteNames = {};
    
    self.ocN  = nil;
    self.ocNE = nil;
    self.ocE  = nil;
    self.ocSE = nil;
    self.ocS  = nil;
    self.ocSW = nil;
    self.ocW  = nil;
    self.ocNW = nil;
    
    if (chordType == CHORD_TYPE_DIM) then
      self.chordNoteIndexes = getNoteIndexesTransposed({"C", "D#", "F#"}, rootNote);
    elseif ( chordType == CHORD_TYPE_MAJ ) then
      self.chordNoteIndexes = getNoteIndexesTransposed({"C", "E", "G"}, rootNote);
    elseif (chordType == CHORD_TYPE_MIN ) then
      self.chordNoteIndexes = getNoteIndexesTransposed({"C", "D#", "G"}, rootNote);
    end
  
    for i=1, table.getn( self.chordNoteIndexes ) do
      self.chordNoteNames[i] = NOTE_PIANO_LOCATION[ self.chordNoteIndexes[i] ];
    end
  
    self.rootNote = rootNote;
    self.cType = chordType;
  end
  
  function OlfChord:setLinks(lN, lNE, lE, lSE, lS, lSW, lW, lNW)
    self.ocN  = lN;
    self.ocNE = lNE;
    self.ocE  = lE;
    self.ocSE = lSE;
    self.ocS  = lS;
    self.ocSW = lSW;
    self.ocW  = lW;
    self.ocNW = lNW;
  end
    
  function OlfChord:moveRandom()    
    local rnd = math.random(1, 8);
    local retry = true;
    local isAnythingButDim = self.chordType ~= CHORD_TYPE_DIM;
    
    while ( retry ) do
      if ( rnd == 1 and self.ocN ~= nil ) then
        return self.ocN;
      elseif  ( rnd == 2 and self.ocNE ~= nil ) then
        return self.ocNE;
      elseif  ( rnd == 3 and isAnythingButDim and self.ocE ~= nil ) then
        return self.ocE;
      elseif  ( rnd == 4 and self.ocSE ~= nil ) then
        return self.ocSE;
      elseif  ( rnd == 5 and self.ocS ~= nil ) then
        return self.ocS;
      elseif  ( rnd == 6 and self.ocSW ~= nil ) then
        return self.ocSW;
      elseif  ( rnd == 7 and isAnythingButDim and self.ocW ~= nil ) then
        return self.ocW;
      elseif  ( rnd == 8 and self.ocNW ~= nil ) then
        return self.ocNW;
      else
        rnd = math.random(1, 8);
      end
    end
  end
  
  function OlfChord:moveLeftOrRight()
    return iif(math.random(0, 1)==0, self.ocW, self.ocE);
  end
  
  function OlfChord:moveMajOrMin()
    if( self.chordType == CHORD_TYPE_MAJ ) then
    
      local rnd = math.random(1, 5);
      if( rnd == 1 or rnd == 2 ) then
        return self:getPossibleLeftOrRight();
      elseif(rnd == 3 or rnd == 4 or rnd == 5) then
        return self:getPossibleDown();
      end
      
    elseif( self.chordType == CHORD_TYPE_MIN) then
    
      local rnd = math.random(1, 5);
      if( rnd == 1 or rnd == 2 ) then
        return self:getPossibleLeftOrRight();
      elseif(rnd == 3 or rnd == 4 or rnd == 5) then
        return self:getPossibleUp();
      end    
      
    else
    
       return self:getPossibleUp();
      
    end
  end--end method
  
  function OlfChord:moveMinOrDim()
    if( self.chordType == CHORD_TYPE_MAJ ) then
    
      return self:getPossibleDown();
      
    elseif( self.chordType == CHORD_TYPE_MIN) then
    
      local rnd = math.random(1, 5);
      if( rnd == 1 or rnd == 2 ) then 
        return self:getPossibleLeftOrRight();
      elseif(rnd == 3 or rnd == 4 or rnd == 5) then
        return self:getPossibleDown();
      end    
      
    else
    
      local rnd = math.random(1, 5); 
      if( rnd == 1 or rnd == 2 ) then
        return self:getPossibleLeftOrRight();
      elseif(rnd == 3 or rnd == 4 or rnd == 5) then
        return self:getPossibleUp();
      end
      
    end    
  end-- end method
  
  function OlfChord:getPossibleUp()
    local retry = true;
    while( retry ) do
      local rnd = math.random(1, 3);
      if( rnd == 1 and self.ocNW ~= nil ) then
        return self.ocNW;
      elseif( rnd == 2 and self.ocN ~= nil ) then
        return self.ocN;
      elseif( rnd == 3 and self.ocNE ~= nil ) then
        return self.ocNE;      
      end
    end -- end while
    return nil; -- unreachable..
  end
  function OlfChord:getPossibleDown()
    local retry = true;
    while( retry ) do
      local rnd = math.random(1, 3);
      if( rnd == 1 and self.ocSW ~= nil ) then
        return self.ocSW;
      elseif( rnd == 2 and self.ocS ~= nil ) then
        return self.ocS;
      elseif( rnd == 3 and self.ocSE ~= nil ) then
        return self.ocSE;
      end
    end -- end while
    return nil; -- unreachable..
  end
  function OlfChord:getPossibleLeftOrRight()
    local retry = true;
    while( retry ) do
      local rnd = math.random(1, 2);
      if( rnd == 1 and self.ocW ~= nil ) then
        return self.ocW;
      elseif( rnd == 2 and self.ocE ~= nil ) then
        return self.ocE;
      end
    end -- end while
    return nil; -- unreachable..   
  end
  
  function OlfChord:getChordAsInts()
    return table.copy( self.chordNoteIndexes );
  end
  
  function OlfChord:getChordAsIntsAddNoteRelativeToFirstNote(nNoteOffset)
    local duplArr = table.copy( self.chordNoteIndexes );    
    duplArr[ table.getn(duplArr)+1 ] = duplArr[1] + nNoteOffset;
    return duplArr;
  end

  function OlfChord:getObjectContentAsString()
    return "[" .. table.concat( self.chordNoteNames, ", " ) .. "] aka " .. self:getShortChordName();
  end  
  
  function OlfChord:getShortChordName()
    local shortType = "";
    if ( self.chordType == "min" ) then
      shortType = "m";
    elseif ( self.chordType == "maj" ) then
      shortType = "";
    elseif ( self.chordType == "dim" ) then
      shortType = "°";
    end
    return self.initialRootNote .. shortType;
  end
  
  
-- class end  


local c1 = {}
local c2 = {}
local c3 = {}

c1[1] = OlfChord("C", CHORD_TYPE_MAJ);
c1[2] = OlfChord("G", CHORD_TYPE_MAJ);
c1[3] = OlfChord("D", CHORD_TYPE_MAJ);
c1[4] = OlfChord("A", CHORD_TYPE_MAJ);
c1[5] = OlfChord("E", CHORD_TYPE_MAJ);
c1[6] = OlfChord("B", CHORD_TYPE_MAJ);
c1[7] = OlfChord("F#", CHORD_TYPE_MAJ);
c1[8] = OlfChord("C#", CHORD_TYPE_MAJ);
c1[9] = OlfChord("G#", CHORD_TYPE_MAJ);
c1[10] = OlfChord("D#", CHORD_TYPE_MAJ);
c1[11] = OlfChord("A#", CHORD_TYPE_MAJ);
c1[12] = OlfChord("F", CHORD_TYPE_MAJ);
c2[1] = OlfChord("E", CHORD_TYPE_MIN);
c2[2] = OlfChord("A", CHORD_TYPE_MIN);
c2[3] = OlfChord("B", CHORD_TYPE_MIN);
c2[4] = OlfChord("E", CHORD_TYPE_MIN);
c2[5] = OlfChord("F#", CHORD_TYPE_MIN);
c2[6] = OlfChord("B", CHORD_TYPE_MIN);
c2[7] = OlfChord("C#", CHORD_TYPE_MIN);
c2[8] = OlfChord("F#", CHORD_TYPE_MIN);
c2[9] = OlfChord("G#", CHORD_TYPE_MIN);
c2[10] = OlfChord("C#", CHORD_TYPE_MIN);
c2[11] = OlfChord("D#", CHORD_TYPE_MIN);
c2[12] = OlfChord("G#", CHORD_TYPE_MIN);
c2[13] = OlfChord("A#", CHORD_TYPE_MIN);
c2[14] = OlfChord("D#", CHORD_TYPE_MIN);
c2[15] = OlfChord("F", CHORD_TYPE_MIN);
c2[16] = OlfChord("A#", CHORD_TYPE_MIN);
c2[17] = OlfChord("C", CHORD_TYPE_MIN);
c2[18] = OlfChord("F", CHORD_TYPE_MIN);
c2[19] = OlfChord("G", CHORD_TYPE_MIN);
c2[20] = OlfChord("C", CHORD_TYPE_MIN);
c2[21] = OlfChord("D", CHORD_TYPE_MIN);
c2[22] = OlfChord("G", CHORD_TYPE_MIN);
c2[23] = OlfChord("A", CHORD_TYPE_MIN);
c2[24] = OlfChord("D", CHORD_TYPE_MIN);
c3[1] = OlfChord("B", CHORD_TYPE_DIM);
c3[2] = OlfChord("F#", CHORD_TYPE_DIM);
c3[3] = OlfChord("C#", CHORD_TYPE_DIM);
c3[4] = OlfChord("G#", CHORD_TYPE_DIM);
c3[5] = OlfChord("D#", CHORD_TYPE_DIM);
c3[6] = OlfChord("A#", CHORD_TYPE_DIM);
c3[7] = OlfChord("F", CHORD_TYPE_DIM);
c3[8] = OlfChord("C", CHORD_TYPE_DIM);
c3[9] = OlfChord("G", CHORD_TYPE_DIM);
c3[10] = OlfChord("D", CHORD_TYPE_DIM);
c3[11] = OlfChord("A", CHORD_TYPE_DIM);
c3[12] = OlfChord("E", CHORD_TYPE_DIM);

c1[1]:setLinks( nil   , nil,    c1[ 2], c2[ 2], c2[ 1], c2[24], c1[12], nil   );
c1[2]:setLinks( nil   , nil,    c1[ 3], c2[ 4], c2[ 3], c2[ 2], c1[ 1], nil   );
c1[3]:setLinks( nil   , nil,    c1[ 4], c2[ 6], c2[ 5], c2[ 4], c1[ 2], nil   );
c1[4]:setLinks( nil   , nil,    c1[ 5], c2[ 8], c2[ 7], c2[ 6], c1[ 3], nil   );
c1[5]:setLinks( nil   , nil,    c1[ 6], c2[10], c2[ 9], c2[ 8], c1[ 4], nil   );
c1[6]:setLinks( nil   , nil,    c1[ 7], c2[12], c2[11], c2[10], c1[ 5], nil   );
c1[7]:setLinks( nil   , nil,    c1[ 8], c2[14], c2[13], c2[12], c1[ 6], nil   );
c1[8]:setLinks( nil   , nil,    c1[ 9], c2[16], c2[15], c2[14], c1[ 7], nil   );
c1[9]:setLinks( nil   , nil,    c1[10], c2[18], c2[17], c2[16], c1[ 8], nil   );
c1[10]:setLinks(nil   , nil,    c1[11], c2[20], c2[19], c2[18], c1[ 9], nil   );
c1[11]:setLinks(nil   , nil,    c1[12], c2[22], c2[21], c2[20], c1[10], nil   );
c1[12]:setLinks(nil   , nil,    c1[ 1], c2[24], c2[23], c2[22], c1[11], nil   );
c3[1]:setLinks( c2[ 1], c2[ 2], c3[ 2], nil   , nil   , nil   , c3[12], c2[24]);
c3[2]:setLinks( c2[ 3], c2[ 4], c3[ 3], nil   , nil   , nil   , c3[ 1], c2[ 2]);
c3[3]:setLinks( c2[ 5], c2[ 6], c3[ 4], nil   , nil   , nil   , c3[ 2], c2[ 4]);
c3[4]:setLinks( c2[ 7], c2[ 8], c3[ 5], nil   , nil   , nil   , c3[ 3], c2[ 6]);
c3[5]:setLinks( c2[ 9], c2[10], c3[ 6], nil   , nil   , nil   , c3[ 4], c2[ 8]);
c3[6]:setLinks( c2[11], c2[12], c3[ 7], nil   , nil   , nil   , c3[ 5], c2[10]);
c3[7]:setLinks( c2[13], c2[14], c3[ 8], nil   , nil   , nil   , c3[ 6], c2[12]);
c3[8]:setLinks( c2[15], c2[16], c3[ 9], nil   , nil   , nil   , c3[ 7], c2[14]);
c3[9]:setLinks( c2[17], c2[18], c3[10], nil   , nil   , nil   , c3[ 8], c2[16]);
c3[10]:setLinks(c2[19], c2[20], c3[11], nil   , nil   , nil   , c3[ 9], c2[18]);
c3[11]:setLinks(c2[21], c2[22], c3[12], nil   , nil   , nil   , c3[10], c2[20]);
c3[12]:setLinks(c2[23], c2[24], c3[ 1], nil   , nil   , nil   , c3[11], c2[22]);
c2[1]:setLinks( c1[ 1], nil   , c2[ 2], nil   , c3[ 1], nil   , c2[24], nil   );
c2[2]:setLinks( nil   , c1[ 2], c2[ 3], c3[ 2], nil   , c3[1] , c2[ 1], c1[ 1]);
c2[3]:setLinks( c1[ 2], nil   , c2[ 4], nil   , c3[ 2], nil   , c2[ 2], nil   );
c2[4]:setLinks( nil   , c1[ 3], c2[ 5], c3[ 3], nil   , c3[2] , c2[ 3], c1[ 2]);
c2[5]:setLinks( c1[ 3], nil   , c2[ 6], nil   , c3[ 3], nil   , c2[ 4], nil   );
c2[6]:setLinks( nil   , c1[ 4], c2[ 7], c3[ 4], nil   , c3[ 3], c2[ 5], c1[ 3]);
c2[7]:setLinks( c1[ 4], nil   , c2[ 8], nil   , c3[ 4], nil   , c2[ 6], nil   );
c2[8]:setLinks( nil   , c1[ 5], c2[ 9], c3[ 5], nil   , c3[ 4], c2[ 7], c1[ 4]);
c2[9]:setLinks( c1[ 5], nil   , c2[10], nil   , c3[ 5], nil   , c2[ 8], nil   );
c2[10]:setLinks(nil   , c1[ 6], c2[11], c3[ 6], nil   , c3[ 5], c2[ 9], c1[ 5]);
c2[11]:setLinks(c1[ 6], nil   , c2[12], nil   , c3[ 6], nil   , c2[10], nil   );
c2[12]:setLinks(nil   , c1[ 7], c2[13], c3[ 7], nil   , c3[ 6], c2[11], c1[ 6]);
c2[13]:setLinks(c1[ 7], nil   , c2[14], nil   , c3[ 7], nil   , c2[12], nil   );
c2[14]:setLinks(nil   , c1[ 8], c2[15], c3[ 8], nil   , c3[ 7], c2[13], c1[ 7]);
c2[15]:setLinks(c1[ 8], nil   , c2[16], nil   , c3[ 8], nil   , c2[14], nil   );
c2[16]:setLinks(nil   , c1[ 9], c2[17], c3[ 9], nil   , c3[ 8], c2[15], c1[ 8]);
c2[17]:setLinks(c1[ 9], nil   , c2[18], nil   , c3[ 9], nil   , c2[16], nil   );
c2[18]:setLinks(nil   , c1[10], c2[19], c3[10], nil   , c3[ 9], c2[17], c1[ 9]);
c2[19]:setLinks(c1[10], nil   , c2[20], nil   , c3[10], nil   , c2[18], nil   );
c2[20]:setLinks(nil   , c1[11], c2[21], c3[11], nil   , c3[10], c2[19], c1[10]);
c2[21]:setLinks(c1[11], nil   , c2[22], nil   , c3[11], nil   , c2[20], nil   );
c2[22]:setLinks(nil   , c1[12], c2[23], c3[12], nil   , c3[11], c2[21], c1[11]);
c2[23]:setLinks(c1[12], nil   , c2[24], nil   , c3[12], nil   , c2[22], nil   );
c2[24]:setLinks(nil   , c1[ 1], c2[ 1], c3[ 1], nil   , c3[12], c2[23], c1[12]);

function getRandomChordsObjects(iNumChords)
  local currMode = LAST_LOCKED_SCALE;
  
  local currChord=nil;
  
  local selectedArray = 1;   
  if( currMode == 1 ) then
    selectedArray = math.random(1, 3);
  elseif( currMode == 2) then
    selectedArray = 1;
  elseif( currMode== 3) then
    selectedArray = 2;
  elseif(currMode == 4) then
    selectedArray = math.random(1, 2);
  elseif(currMode == 5) then
    selectedArray = math.random(2, 3);
  end
  
  local arrBack = {}
  
  if (selectedArray == 1) then
    currChord = c1[ math.random(1, table.getn(c1)) ];
    if( LAST_SELECTED_BEGIN_NOTE > 1) then
      currChord = findChordByANoteIndex(c1, LAST_SELECTED_BEGIN_NOTE - 1);
    end
  elseif ( selectedArray == 2) then
    currChord = c2[ math.random(1, table.getn(c2)) ];
    if( LAST_SELECTED_BEGIN_NOTE > 1) then
      currChord = findChordByANoteIndex(c2, LAST_SELECTED_BEGIN_NOTE - 1);
    end    
  elseif (selectedArray == 3) then
    currChord = c3[ math.random(1, table.getn(c3)) ];
    if( LAST_SELECTED_BEGIN_NOTE > 1) then
      currChord = findChordByANoteIndex(c3, LAST_SELECTED_BEGIN_NOTE - 1);
    end    
  end
  
  arrBack[1] = currChord;
  for i=2, iNumChords do
    if( currMode == 1 ) then
      currChord = currChord:moveRandom();
    else
      if( currMode == 2 or currMode == 3) then
        currChord = currChord:moveLeftOrRight();
      elseif( currMode == 4) then
        currChord = currChord:moveMajOrMin();
      elseif( currMode == 5) then
        currChord = currChord:moveMinOrDim();
      end
    end
    arrBack[i] = currChord;
  end
  
  return arrBack;
end

function findChordByANoteIndex(arrToSearch, iNoteIndex)
  local noteName = NOTE_PIANO_LOCATION[ iNoteIndex ];
  
  local rndDirection = math.random(1,2);
  
  local arrLen = table.getn( arrToSearch );
  
  if( rndDirection == 1 ) then
    for i=1, arrLen do
      if( arrToSearch[i].initialRootNote == noteName ) then
        return arrToSearch[i];
      end
    end
  elseif( rndDirection == 2 ) then
    for i=1, arrLen do
      if( arrToSearch[(arrLen+1)-i].initialRootNote == noteName ) then
        return arrToSearch[(arrLen+1)-i];
      end
    end
  end
  
  return nil;
end

--------------------------------------------------
-------------------- - - - - ---------------------
--------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Chord Progression tool...",
  invoke = show_gui
}

--------------------------------------------------
-------------------- - - - - ---------------------
--------------------------------------------------


