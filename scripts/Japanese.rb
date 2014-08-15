#!/usr/bin/ruby -w
#encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__)

module Japanese

  # Punctuation is repeated in hiragana and katakana for simplicity
  HIRAGANA_TO_UNICODE = {
#    :","  => 0x3001, :"." => 0x3002, :"[" => 0x300c, :"]" => 0x300d,
    :a    => 0x3042, :i   => 0x3044, :u   => 0x3046, :e   => 0x3048, :o  => 0x304a,
    :ka   => 0x304b, :ki  => 0x304d, :ku  => 0x304f, :ke  => 0x3051, :ko => 0x3053,
    :ga   => 0x304c, :gi  => 0x304e, :gu  => 0x3050, :ge  => 0x3052, :go => 0x3054,
    :sa   => 0x3055, :si  => 0x3057, :su  => 0x3059, :se  => 0x305b, :so => 0x305d,
    :za   => 0x3056, :ji  => 0x3058, :zu  => 0x305a, :ze  => 0x305c, :zo => 0x305e,
    :ta   => 0x305f, :ti  => 0x3061, :tu  => 0x3064, :te  => 0x3066, :to => 0x3068,
    :da   => 0x3060, :di  => 0x3062, :du  => 0x3065, :de  => 0x3067, :do => 0x3069,
    :na   => 0x306a, :ni  => 0x306b, :nu  => 0x306c, :ne  => 0x306d, :no => 0x306e,
    :ha   => 0x306f, :hi  => 0x3072, :fu  => 0x3075, :he  => 0x3078, :ho => 0x307b,
    :ba   => 0x3070, :bi  => 0x3073, :bu  => 0x3076, :be  => 0x3079, :bo => 0x307c,
    :pa   => 0x3071, :pi  => 0x3074, :pu  => 0x3077, :pe  => 0x307a, :po => 0x307d,
    :ma   => 0x307e, :mi  => 0x307f, :mu  => 0x3080, :me  => 0x3081, :mo => 0x3082,
    :ya   => 0x3084,                 :yu  => 0x3086,                 :yo => 0x3088,
    :ra   => 0x3089, :ri  => 0x308a, :ru  => 0x308b, :re  => 0x308c, :ro => 0x308d,
    :wa   => 0x308f, :wi  => 0x3090,                 :we  => 0x3091, :wo => 0x3092,
    :nn => 0x3093,
    # Alternatives below here
    :shi  => 0x3057, # see :si
    :zi   => 0x3058, # see :ji
    :chi  => 0x3061, # see :ti
    :tsu  => 0x3064, # see :t
    :hu   => 0x3075, # see :fu
    :"n'" => 0x3093,

    :small_ya => 0x3083,
    :small_yu => 0x3085,
    :small_yo => 0x3087,
  }.freeze()

  # Punctuation is repeated in hiragana and katakana for simplicity
  KATAKANA_TO_UNICODE = {
#    :","  => 0x3001, :"." => 0x3002, :"[" => 0x300c, :"]" => 0x300d
    :a    => 0x30a2, :i   => 0x30a4, :u   => 0x30a6, :e   => 0x30a8, :o  => 0x30aa,
    :ka   => 0x30ab, :ki  => 0x30ad, :ku  => 0x30af, :ke  => 0x30b1, :ko => 0x30b3,
    :ga   => 0x30ac, :gi  => 0x30ae, :gu  => 0x30b0, :ge  => 0x30b2, :go => 0x30b4,
    :sa   => 0x30b5, :si  => 0x30b7, :su  => 0x30b9, :se  => 0x30bb, :so => 0x30bd,
    :za   => 0x30b6, :ji  => 0x30b8, :zu  => 0x30ba, :ze  => 0x30bc, :zo => 0x30be,
    :ta   => 0x30bf, :ti  => 0x30c1, :tu  => 0x30c4, :te  => 0x30c6, :to => 0x30c8,
    :da   => 0x30c0, :di  => 0x30c2, :du  => 0x30c5, :de  => 0x30c7, :do => 0x30c9,
    :na   => 0x30ca, :ni  => 0x30cb, :nu  => 0x30cc, :ne  => 0x30cd, :no => 0x30ce,
    :ha   => 0x30cf, :hi  => 0x30d2, :fu  => 0x30d5, :he  => 0x30d8, :ho => 0x30db,
    :ba   => 0x30d0, :bi  => 0x30d3, :bu  => 0x30d6, :be  => 0x30d9, :bo => 0x30dc,
    :pa   => 0x30d1, :pi  => 0x30d4, :pu  => 0x30d7, :pe  => 0x30da, :po => 0x30dd,
    :ma   => 0x30de, :mi  => 0x30df, :mu  => 0x30e0, :me  => 0x30e1, :mo => 0x30e2,
    :ya   => 0x30e4,                 :yu  => 0x30e6,                 :yo => 0x30e8,
    :ra   => 0x30e9, :ri  => 0x30ea, :ru  => 0x30eb, :re  => 0x30ec, :ro => 0x30ed,
    :wa   => 0x30ef, :wi  => 0x30f0,                 :we  => 0x30f1, :wo => 0x30f2,
    :nn   => 0x30f3,
     # Alternatives  below here
    :shi  => 0x30b7,
    :zi   => 0x30b8,
    :chi  => 0x30c1,
    :tsu  => 0x30c4,
    :hu   => 0x30d5,
    :"n'" => 0x30f3,

    :small_ya => 0x30e3,
    :small_yu => 0x30e5,
    :small_yo => 0x30e7,
  }.freeze()

end
