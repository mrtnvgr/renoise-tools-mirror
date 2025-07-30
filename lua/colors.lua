--
--  colors
--


--pad colors
function kng_pad_clr( val )
  --vws["KNG_PAD_BACKGROUND_"..i].color = KNG_CLR.DEFAULT
  if     ( val ==  1 ) then --1x2
    for i = 0, 119 do
      local back = vws["KNG_PAD_BACKGROUND_"..i]
      if     ( i < 2 ) then back.color = KNG_CLR.RED_1
      elseif ( i < 4 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 6 ) then back.color = KNG_CLR.RED_3
      elseif ( i < 8 ) then back.color = KNG_CLR.RED_4
      --
      elseif ( i < 10 ) then back.color = KNG_CLR.GREEN_1
      elseif ( i < 12 ) then back.color = KNG_CLR.GREEN_2
      elseif ( i < 14 ) then back.color = KNG_CLR.GREEN_3
      elseif ( i < 16 ) then back.color = KNG_CLR.GREEN_4
      --
      elseif ( i < 18 ) then back.color = KNG_CLR.BLUE_1
      elseif ( i < 20 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 22 ) then back.color = KNG_CLR.BLUE_3
      elseif ( i < 24 ) then back.color = KNG_CLR.BLUE_4
      --
      elseif ( i < 26 ) then back.color = KNG_CLR.YELLOW_1
      elseif ( i < 28 ) then back.color = KNG_CLR.YELLOW_2
      elseif ( i < 30 ) then back.color = KNG_CLR.YELLOW_3
      elseif ( i < 32 ) then back.color = KNG_CLR.YELLOW_4
      --
      elseif ( i < 34 ) then back.color = KNG_CLR.PINK_1
      elseif ( i < 36 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 38 ) then back.color = KNG_CLR.PINK_3
      elseif ( i < 40 ) then back.color = KNG_CLR.PINK_4
      --      
      elseif ( i < 42 ) then back.color = KNG_CLR.ORANGE_1
      elseif ( i < 44 ) then back.color = KNG_CLR.ORANGE_2
      elseif ( i < 46 ) then back.color = KNG_CLR.ORANGE_3
      elseif ( i < 48 ) then back.color = KNG_CLR.ORANGE_4
      --
      elseif ( i < 50 ) then back.color = KNG_CLR.VIOLET_1
      elseif ( i < 52 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 54 ) then back.color = KNG_CLR.VIOLET_3
      elseif ( i < 56 ) then back.color = KNG_CLR.VIOLET_4
      --
      elseif ( i < 58 ) then back.color = KNG_CLR.GRAY_1
      elseif ( i < 60 ) then back.color = KNG_CLR.GRAY_2
      elseif ( i < 62 ) then back.color = KNG_CLR.GRAY_3
      elseif ( i < 64 ) then back.color = KNG_CLR.GRAY_4
      --
      elseif ( i < 66 ) then back.color = KNG_CLR.RED_1
      elseif ( i < 68 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 70 ) then back.color = KNG_CLR.RED_3
      elseif ( i < 72 ) then back.color = KNG_CLR.RED_4
      --
      elseif ( i < 74 ) then back.color = KNG_CLR.GREEN_1
      elseif ( i < 76 ) then back.color = KNG_CLR.GREEN_2
      elseif ( i < 78 ) then back.color = KNG_CLR.GREEN_3
      elseif ( i < 80 ) then back.color = KNG_CLR.GREEN_4
      --
      elseif ( i < 82 ) then back.color = KNG_CLR.BLUE_1
      elseif ( i < 84 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 86 ) then back.color = KNG_CLR.BLUE_3
      elseif ( i < 88 ) then back.color = KNG_CLR.BLUE_4
      --
      elseif ( i < 90 ) then back.color = KNG_CLR.YELLOW_1
      elseif ( i < 92 ) then back.color = KNG_CLR.YELLOW_2
      elseif ( i < 94 ) then back.color = KNG_CLR.YELLOW_3
      elseif ( i < 96 ) then back.color = KNG_CLR.YELLOW_4
      --
      elseif ( i < 98 ) then back.color = KNG_CLR.PINK_1
      elseif ( i < 100 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 102 ) then back.color = KNG_CLR.PINK_3
      elseif ( i < 104 ) then back.color = KNG_CLR.PINK_4
      --      
      elseif ( i < 106 ) then back.color = KNG_CLR.ORANGE_1
      elseif ( i < 108 ) then back.color = KNG_CLR.ORANGE_2
      elseif ( i < 110 ) then back.color = KNG_CLR.ORANGE_3
      elseif ( i < 112 ) then back.color = KNG_CLR.ORANGE_4
      --
      elseif ( i < 114 ) then back.color = KNG_CLR.VIOLET_1
      elseif ( i < 116 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 118 ) then back.color = KNG_CLR.VIOLET_3
      --
      else back.color = KNG_CLR.VIOLET_4
      end
    end
  elseif ( val ==  2 ) then --1x4
    for i = 0, 119 do
      local back = vws["KNG_PAD_BACKGROUND_"..i]
          if ( i < 4 ) then back.color = KNG_CLR.RED_1
      elseif ( i < 8 ) then back.color = KNG_CLR.RED_2
      --
      elseif ( i < 12 ) then back.color = KNG_CLR.GREEN_1
      elseif ( i < 16 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 20 ) then back.color = KNG_CLR.BLUE_1
      elseif ( i < 24 ) then back.color = KNG_CLR.BLUE_2
      --
      elseif ( i < 28 ) then back.color = KNG_CLR.YELLOW_1
      elseif ( i < 32 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 36 ) then back.color = KNG_CLR.PINK_1
      elseif ( i < 40 ) then back.color = KNG_CLR.PINK_2
      --      
      elseif ( i < 44 ) then back.color = KNG_CLR.ORANGE_1
      elseif ( i < 48 ) then back.color = KNG_CLR.ORANGE_2
      --
      elseif ( i < 52 ) then back.color = KNG_CLR.VIOLET_1
      elseif ( i < 56 ) then back.color = KNG_CLR.VIOLET_2
      --
      elseif ( i < 60 ) then back.color = KNG_CLR.GRAY_1
      elseif ( i < 64 ) then back.color = KNG_CLR.GRAY_2
      --
      elseif ( i < 68 ) then back.color = KNG_CLR.RED_1
      elseif ( i < 72 ) then back.color = KNG_CLR.RED_2
      --
      elseif ( i < 76 ) then back.color = KNG_CLR.GREEN_1
      elseif ( i < 80 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 84 ) then back.color = KNG_CLR.BLUE_1
      elseif ( i < 88 ) then back.color = KNG_CLR.BLUE_2
      --
      elseif ( i < 92 ) then back.color = KNG_CLR.YELLOW_1
      elseif ( i < 96 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 100 ) then back.color = KNG_CLR.PINK_1
      elseif ( i < 104 ) then back.color = KNG_CLR.PINK_2
      --      
      elseif ( i < 108 ) then back.color = KNG_CLR.ORANGE_1
      elseif ( i < 112 ) then back.color = KNG_CLR.ORANGE_2
      --
      elseif ( i < 116 ) then back.color = KNG_CLR.VIOLET_1
      --
      else back.color = KNG_CLR.VIOLET_2
      end
    end
  elseif ( val ==  3 ) then --1x8
    for i = 0, 119 do
      local back = vws["KNG_PAD_BACKGROUND_"..i]
      if     ( i < 8 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 16 ) then back.color = KNG_CLR.RED_3
      elseif ( i < 24 ) then back.color = KNG_CLR.GREEN_2
      elseif ( i < 32 ) then back.color = KNG_CLR.GREEN_3
      elseif ( i < 40 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 48 ) then back.color = KNG_CLR.BLUE_3
      elseif ( i < 56 ) then back.color = KNG_CLR.YELLOW_2
      elseif ( i < 64 ) then back.color = KNG_CLR.YELLOW_3
      elseif ( i < 72 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 80 ) then back.color = KNG_CLR.PINK_3
      elseif ( i < 88 ) then back.color = KNG_CLR.ORANGE_2
      elseif ( i < 96 ) then back.color = KNG_CLR.ORANGE_3
      elseif ( i <104 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i <112 ) then back.color = KNG_CLR.VIOLET_3
      else back.color = KNG_CLR.GRAY_3
      end
    end
  elseif ( val ==  4 ) then --2x2
    for i = 0, 119 do
      local back = vws["KNG_PAD_BACKGROUND_"..i]
      if     ( i < 2 ) then back.color = KNG_CLR.RED_1
      elseif ( i < 4 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 6 ) then back.color = KNG_CLR.RED_3
      elseif ( i < 8 ) then back.color = KNG_CLR.RED_4
      --
      elseif ( i < 10 ) then back.color = KNG_CLR.RED_1
      elseif ( i < 12 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 14 ) then back.color = KNG_CLR.RED_3
      elseif ( i < 16 ) then back.color = KNG_CLR.RED_4
      --
      elseif ( i < 18 ) then back.color = KNG_CLR.GREEN_1
      elseif ( i < 20 ) then back.color = KNG_CLR.GREEN_2
      elseif ( i < 22 ) then back.color = KNG_CLR.GREEN_3
      elseif ( i < 24 ) then back.color = KNG_CLR.GREEN_4
      --
      elseif ( i < 26 ) then back.color = KNG_CLR.GREEN_1
      elseif ( i < 28 ) then back.color = KNG_CLR.GREEN_2
      elseif ( i < 30 ) then back.color = KNG_CLR.GREEN_3
      elseif ( i < 32 ) then back.color = KNG_CLR.GREEN_4
      --
      elseif ( i < 34 ) then back.color = KNG_CLR.BLUE_1
      elseif ( i < 36 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 38 ) then back.color = KNG_CLR.BLUE_3
      elseif ( i < 40 ) then back.color = KNG_CLR.BLUE_4
      --      
      elseif ( i < 42 ) then back.color = KNG_CLR.BLUE_1
      elseif ( i < 44 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 46 ) then back.color = KNG_CLR.BLUE_3
      elseif ( i < 48 ) then back.color = KNG_CLR.BLUE_4
      --
      elseif ( i < 50 ) then back.color = KNG_CLR.YELLOW_1
      elseif ( i < 52 ) then back.color = KNG_CLR.YELLOW_2
      elseif ( i < 54 ) then back.color = KNG_CLR.YELLOW_3
      elseif ( i < 56 ) then back.color = KNG_CLR.YELLOW_4
      --
      elseif ( i < 58 ) then back.color = KNG_CLR.YELLOW_1
      elseif ( i < 60 ) then back.color = KNG_CLR.YELLOW_2
      elseif ( i < 62 ) then back.color = KNG_CLR.YELLOW_3
      elseif ( i < 64 ) then back.color = KNG_CLR.YELLOW_4
      --
      elseif ( i < 66 ) then back.color = KNG_CLR.PINK_1
      elseif ( i < 68 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 70 ) then back.color = KNG_CLR.PINK_3
      elseif ( i < 72 ) then back.color = KNG_CLR.PINK_4
      --
      elseif ( i < 74 ) then back.color = KNG_CLR.PINK_1
      elseif ( i < 76 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 78 ) then back.color = KNG_CLR.PINK_3
      elseif ( i < 80 ) then back.color = KNG_CLR.PINK_4
      --
      elseif ( i < 82 ) then back.color = KNG_CLR.ORANGE_1
      elseif ( i < 84 ) then back.color = KNG_CLR.ORANGE_2
      elseif ( i < 86 ) then back.color = KNG_CLR.ORANGE_3
      elseif ( i < 88 ) then back.color = KNG_CLR.ORANGE_4
      --
      elseif ( i < 90 ) then back.color = KNG_CLR.ORANGE_1
      elseif ( i < 92 ) then back.color = KNG_CLR.ORANGE_2
      elseif ( i < 94 ) then back.color = KNG_CLR.ORANGE_3
      elseif ( i < 96 ) then back.color = KNG_CLR.ORANGE_4
      --
      elseif ( i < 98 ) then back.color = KNG_CLR.VIOLET_1
      elseif ( i < 100 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 102 ) then back.color = KNG_CLR.VIOLET_3
      elseif ( i < 104 ) then back.color = KNG_CLR.VIOLET_4
      --      
      elseif ( i < 106 ) then back.color = KNG_CLR.VIOLET_1
      elseif ( i < 108 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 110 ) then back.color = KNG_CLR.VIOLET_3
      elseif ( i < 112 ) then back.color = KNG_CLR.VIOLET_4
      --
      elseif ( i < 114 ) then back.color = KNG_CLR.GRAY_1
      elseif ( i < 116 ) then back.color = KNG_CLR.GRAY_2
      elseif ( i < 118 ) then back.color = KNG_CLR.GRAY_3
      --
      else back.color = KNG_CLR.GRAY_4
      end
    end
  elseif ( val ==  5 ) then --2x4
    for i = 0, 119 do
      local back = vws["KNG_PAD_BACKGROUND_"..i]
          if ( i < 4 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 8 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 12 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 16 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 20 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 24 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 28 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 32 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 36 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 40 ) then back.color = KNG_CLR.ORANGE_2
      --      
      elseif ( i < 44 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 48 ) then back.color = KNG_CLR.ORANGE_2
      --
      elseif ( i < 52 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 56 ) then back.color = KNG_CLR.GRAY_2
      --
      elseif ( i < 60 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 64 ) then back.color = KNG_CLR.GRAY_2
      --
      elseif ( i < 68 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 72 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 76 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 80 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 84 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 88 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 92 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 96 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 100 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 104 ) then back.color = KNG_CLR.ORANGE_2
      --      
      elseif ( i < 108 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 112 ) then back.color = KNG_CLR.ORANGE_2
      --
      elseif ( i < 116 ) then back.color = KNG_CLR.VIOLET_2
      --
      else back.color = KNG_CLR.GRAY_2
      end
    end
  elseif ( val ==  6 ) then --2x8
    for i = 0, 119 do
      local back = vws["KNG_PAD_BACKGROUND_"..i]
      if     ( i < 16 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 32 ) then back.color = KNG_CLR.GREEN_2
      elseif ( i < 48 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 64 ) then back.color = KNG_CLR.YELLOW_2
      elseif ( i < 80 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 96 ) then back.color = KNG_CLR.ORANGE_2
      elseif ( i <112 ) then back.color = KNG_CLR.VIOLET_2
      else back.color = KNG_CLR.GRAY_3
      end
    end
  elseif ( val ==  7 ) then --3x2
    for i = 0, 119 do
      local back = vws["KNG_PAD_BACKGROUND_"..i]
      if     ( i < 2 ) then back.color = KNG_CLR.RED_1
      elseif ( i < 4 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 6 ) then back.color = KNG_CLR.RED_3
      elseif ( i < 8 ) then back.color = KNG_CLR.RED_4
      --
      elseif ( i < 10 ) then back.color = KNG_CLR.RED_1
      elseif ( i < 12 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 14 ) then back.color = KNG_CLR.RED_3
      elseif ( i < 16 ) then back.color = KNG_CLR.RED_4
      --
      elseif ( i < 18 ) then back.color = KNG_CLR.RED_1
      elseif ( i < 20 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 22 ) then back.color = KNG_CLR.RED_3
      elseif ( i < 24 ) then back.color = KNG_CLR.RED_4
      --
      elseif ( i < 26 ) then back.color = KNG_CLR.GREEN_1
      elseif ( i < 28 ) then back.color = KNG_CLR.GREEN_2
      elseif ( i < 30 ) then back.color = KNG_CLR.GREEN_3
      elseif ( i < 32 ) then back.color = KNG_CLR.GREEN_4
      --
      elseif ( i < 34 ) then back.color = KNG_CLR.GREEN_1
      elseif ( i < 36 ) then back.color = KNG_CLR.GREEN_2
      elseif ( i < 38 ) then back.color = KNG_CLR.GREEN_3
      elseif ( i < 40 ) then back.color = KNG_CLR.GREEN_4
      --      
      elseif ( i < 42 ) then back.color = KNG_CLR.GREEN_1
      elseif ( i < 44 ) then back.color = KNG_CLR.GREEN_2
      elseif ( i < 46 ) then back.color = KNG_CLR.GREEN_3
      elseif ( i < 48 ) then back.color = KNG_CLR.GREEN_4
      --
      elseif ( i < 50 ) then back.color = KNG_CLR.BLUE_1
      elseif ( i < 52 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 54 ) then back.color = KNG_CLR.BLUE_3
      elseif ( i < 56 ) then back.color = KNG_CLR.BLUE_4
      --
      elseif ( i < 58 ) then back.color = KNG_CLR.BLUE_1
      elseif ( i < 60 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 62 ) then back.color = KNG_CLR.BLUE_3
      elseif ( i < 64 ) then back.color = KNG_CLR.BLUE_4
      --
      elseif ( i < 66 ) then back.color = KNG_CLR.BLUE_1
      elseif ( i < 68 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 70 ) then back.color = KNG_CLR.BLUE_3
      elseif ( i < 72 ) then back.color = KNG_CLR.BLUE_4
      --
      elseif ( i < 74 ) then back.color = KNG_CLR.YELLOW_1
      elseif ( i < 76 ) then back.color = KNG_CLR.YELLOW_2
      elseif ( i < 78 ) then back.color = KNG_CLR.YELLOW_3
      elseif ( i < 80 ) then back.color = KNG_CLR.YELLOW_4
      --
      elseif ( i < 82 ) then back.color = KNG_CLR.YELLOW_1
      elseif ( i < 84 ) then back.color = KNG_CLR.YELLOW_2
      elseif ( i < 86 ) then back.color = KNG_CLR.YELLOW_3
      elseif ( i < 88 ) then back.color = KNG_CLR.YELLOW_4
      --
      elseif ( i < 90 ) then back.color = KNG_CLR.YELLOW_1
      elseif ( i < 92 ) then back.color = KNG_CLR.YELLOW_2
      elseif ( i < 94 ) then back.color = KNG_CLR.YELLOW_3
      elseif ( i < 96 ) then back.color = KNG_CLR.YELLOW_4
      --
      elseif ( i < 98 ) then back.color = KNG_CLR.PINK_1
      elseif ( i < 100 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 102 ) then back.color = KNG_CLR.PINK_3
      elseif ( i < 104 ) then back.color = KNG_CLR.PINK_4
      --      
      elseif ( i < 106 ) then back.color = KNG_CLR.PINK_1
      elseif ( i < 108 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 110 ) then back.color = KNG_CLR.PINK_3
      elseif ( i < 112 ) then back.color = KNG_CLR.PINK_4
      --
      elseif ( i < 114 ) then back.color = KNG_CLR.PINK_1
      elseif ( i < 116 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 118 ) then back.color = KNG_CLR.PINK_3
      --
      else back.color = KNG_CLR.PINK_4
      end
    end  
  elseif ( val ==  8 ) then --3x4
    for i = 0, 119 do
      local back = vws["KNG_PAD_BACKGROUND_"..i]
          if ( i < 4 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 8 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 12 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 16 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 20 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 24 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 28 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 32 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 36 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 40 ) then back.color = KNG_CLR.YELLOW_2
      --      
      elseif ( i < 44 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 48 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 52 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 56 ) then back.color = KNG_CLR.ORANGE_2
      --
      elseif ( i < 60 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 64 ) then back.color = KNG_CLR.ORANGE_2
      --
      elseif ( i < 68 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 72 ) then back.color = KNG_CLR.ORANGE_2
      --
      elseif ( i < 76 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 80 ) then back.color = KNG_CLR.GRAY_2
      --
      elseif ( i < 84 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 88 ) then back.color = KNG_CLR.GRAY_2
      --
      elseif ( i < 92 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 96 ) then back.color = KNG_CLR.GRAY_2
      --
      elseif ( i < 100 ) then back.color = KNG_CLR.RED_3
      elseif ( i < 104 ) then back.color = KNG_CLR.GREEN_3
      --      
      elseif ( i < 108 ) then back.color = KNG_CLR.RED_3
      elseif ( i < 112 ) then back.color = KNG_CLR.GREEN_3
      --
      elseif ( i < 116 ) then back.color = KNG_CLR.RED_3
      --
      else back.color = KNG_CLR.GREEN_3
      end
    end
  elseif ( val ==  9 ) then --3x8
    for i = 0, 119 do
      local back = vws["KNG_PAD_BACKGROUND_"..i]
      if     ( i < 24 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 48 ) then back.color = KNG_CLR.GREEN_2
      elseif ( i < 72 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 96 ) then back.color = KNG_CLR.YELLOW_2
      else back.color = KNG_CLR.PINK_2
      end
    end  
  elseif ( val == 10 ) then --4x2
    for i = 0, 119 do
      local back = vws["KNG_PAD_BACKGROUND_"..i]
          if ( i < 4 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 8 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 12 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 16 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 20 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 24 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 28 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 32 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 36 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 40 ) then back.color = KNG_CLR.ORANGE_2
      --      
      elseif ( i < 44 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 48 ) then back.color = KNG_CLR.ORANGE_2
      --
      elseif ( i < 52 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 56 ) then back.color = KNG_CLR.GRAY_2
      --
      elseif ( i < 60 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 64 ) then back.color = KNG_CLR.GRAY_2
      --
      elseif ( i < 68 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 72 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 76 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 80 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 84 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 88 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 92 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 96 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 100 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 104 ) then back.color = KNG_CLR.ORANGE_2
      --      
      elseif ( i < 108 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 112 ) then back.color = KNG_CLR.ORANGE_2
      --
      elseif ( i < 116 ) then back.color = KNG_CLR.VIOLET_2
      --
      else back.color = KNG_CLR.GRAY_2
      end
    end
  elseif ( val == 11 ) then --4x4
    for i = 0, 119 do
      local back = vws["KNG_PAD_BACKGROUND_"..i]
          if ( i < 4 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 8 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 12 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 16 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 20 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 24 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 28 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 32 ) then back.color = KNG_CLR.GREEN_2
      --
      elseif ( i < 36 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 40 ) then back.color = KNG_CLR.YELLOW_2
      --      
      elseif ( i < 44 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 48 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 52 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 56 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 60 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 64 ) then back.color = KNG_CLR.YELLOW_2
      --
      elseif ( i < 68 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 72 ) then back.color = KNG_CLR.ORANGE_2
      --
      elseif ( i < 76 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 80 ) then back.color = KNG_CLR.ORANGE_2
      --
      elseif ( i < 84 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 88 ) then back.color = KNG_CLR.ORANGE_2
      --
      elseif ( i < 92 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 96 ) then back.color = KNG_CLR.ORANGE_2
      --
      elseif ( i < 100 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 104 ) then back.color = KNG_CLR.GRAY_2
      --      
      elseif ( i < 108 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 112 ) then back.color = KNG_CLR.GRAY_2 
      --
      elseif ( i < 116 ) then back.color = KNG_CLR.VIOLET_2
      --
      else back.color = KNG_CLR.GRAY_2
      end
    end
  elseif ( val == 12 ) then --4x8
    for i = 0, 119 do
      local back = vws["KNG_PAD_BACKGROUND_"..i]
      if     ( i < 32 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 64 ) then back.color = KNG_CLR.GREEN_2
      elseif ( i < 96 ) then back.color = KNG_CLR.BLUE_2
      else back.color = KNG_CLR.YELLOW_2
      end
    end
  elseif ( val == 13 ) then
    for i = 0, 119 do
      local back = vws["KNG_PAD_BACKGROUND_"..i]
      if     ( i < 12 ) then back.color = KNG_CLR.RED_2
      elseif ( i < 24 ) then back.color = KNG_CLR.GREEN_2
      elseif ( i < 36 ) then back.color = KNG_CLR.BLUE_2
      elseif ( i < 48 ) then back.color = KNG_CLR.YELLOW_2
      elseif ( i < 60 ) then back.color = KNG_CLR.PINK_2
      elseif ( i < 72 ) then back.color = KNG_CLR.ORANGE_2
      elseif ( i < 84 ) then back.color = KNG_CLR.VIOLET_2
      elseif ( i < 96 ) then back.color = KNG_CLR.GRAY_2
      elseif ( i <108 ) then back.color = KNG_CLR.RED_3
      else back.color = KNG_CLR.GREEN_3
      end
    end  
  elseif ( val == 14 ) then --dark color
    for i = 0, 119 do
      vws["KNG_PAD_BACKGROUND_"..i].color = KNG_CLR.GRAY_2
    end
  else --clear color
    for i = 0, 119 do
      vws["KNG_PAD_BACKGROUND_"..i].color = KNG_CLR.GRAY_3
    end
  end
end
