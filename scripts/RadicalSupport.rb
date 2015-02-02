#!/usr/bin/ruby -w
#encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__)

require 'KanjiSupport.rb'
require 'Radical.rb'
require 'UnicodeSupport.rb'

require 'singleton.rb'

class RD
  include Singleton
  attr_reader :radical
  def initialize()
    @radical = {
    "one" =>                Radical.new("one",                "ICHI",           find_kanji_unicode_from_keyword("one")),
    "line" =>               Radical.new("line",               "BOU",            20008),
    "dot" =>                Radical.new("dot",                "TEN'",           20022),
    "bend" =>               Radical.new("bend",               "NO",             20031),
    "second" =>             Radical.new("second",             "OTSU",           find_kanji_unicode_from_keyword("fish*guts")),   # alternative 20058
    "hook" =>               Radical.new("hook",               "HANEBOU",        20101),
    "two" =>                Radical.new("two",                "FUTA",           find_kanji_unicode_from_keyword("two")),
    "lid" =>                Radical.new("lid",                "NABEBUTA",       20128),
    "human" =>              Radical.new("human",              "HITO",           find_kanji_unicode_from_keyword("person")),      # alternative 20155
    "legs" =>               Radical.new("legs",               "NIN'NYOU",       20799),
    "enter" =>              Radical.new("enter",              "IRU",            find_kanji_unicode_from_keyword("enter")),
    "eight" =>              Radical.new("eight",              "HACHIGASHIRA",   find_kanji_unicode_from_keyword("eight")),
    "upside*down*box" =>    Radical.new("upside*down*box",    "MAKIGAMAE",      20866),
    "cover" =>              Radical.new("cover",              "WAKANMURI",      20886),
    "ice" =>                Radical.new("ice",                "NISUI",          20907),
    "desk" =>               Radical.new("desk",               "TSUKUE",         20960),
    "container" =>          Radical.new("container",          "UKEBAKO",        20981),
    "knife" =>              Radical.new("knife",              "KATANA",         find_kanji_unicode_from_keyword("sword")),       # alternative: 20994, 
    "power" =>              Radical.new("power",              "CHIKARA",        find_kanji_unicode_from_keyword("power")),
    "wrap" =>               Radical.new("wrap",               "TSUTSUMIGAMAE",  21241),
    "spoon" =>              Radical.new("spoon",              "SAJINOHI",       find_kanji_unicode_from_keyword("spoon")),
    "box" =>                Radical.new("box",                "HAKOGAMAE",      21274),
    "dead" =>               Radical.new("dead",               "KAKUSHIGAMAE",   find_kanji_unicode_from_keyword("deceased")),    # alternative: 21304
    "ten" =>                Radical.new("ten",                "JUU",            find_kanji_unicode_from_keyword("ten")),
    "divination" =>         Radical.new("divination",         "BOKUNOTO",       find_kanji_unicode_from_keyword("augury")),
    "seal" =>               Radical.new("seal",               "FUSHIDUKURI",    21353),
    "cliff" =>              Radical.new("cliff",              "GANDARE",        21378),
    "private" =>            Radical.new("private",            "MU",             21430),
    "again" =>              Radical.new("again",              "MATA",           find_kanji_unicode_from_keyword("or*again")),
    "mouth" =>              Radical.new("mouth",              "KUCHI",          find_kanji_unicode_from_keyword("mouth")),
    "enclosure" =>          Radical.new("enclosure",          "KUNIGAMAE",      22231),
    "earth" =>              Radical.new("earth",              "TSUCHI",         find_kanji_unicode_from_keyword("soil")),
    "scholar" =>            Radical.new("scholar",            "SAMURAI",        find_kanji_unicode_from_keyword("gentleman")),
    "winter" =>             Radical.new("winter",             "FUYUGASHIRA",    22786),
    "winter*variant" =>     Radical.new("winter*variant",     "SUINYOU",        22794),
    "evening" =>            Radical.new("evening",            "YUUBE",          find_kanji_unicode_from_keyword("evening")),
    "big" =>                Radical.new("big",                "DAI",            find_kanji_unicode_from_keyword("large")),
    "woman" =>              Radical.new("woman",              "ON'NA",          find_kanji_unicode_from_keyword("woman")),
    "child" =>              Radical.new("child",              "KO",             find_kanji_unicode_from_keyword("child")),
    "roof" =>               Radical.new("roof",               "UKANMURI",       23424),
    "sun*(unit)" =>         Radical.new("sun*(unit)",         "SUN'",           find_kanji_unicode_from_keyword("measurement")),
    "small" =>              Radical.new("small",              "CHIISAI",        find_kanji_unicode_from_keyword("little")),
    "lame" =>               Radical.new("lame",               "MAGEASHI",       23586),
    "corpse" =>             Radical.new("corpse",             "SHIKABANE",      23608),
    "sprout" =>             Radical.new("sprout",             "TETSU",          23662),
    "mountain" =>           Radical.new("mountain",           "YAMA",           find_kanji_unicode_from_keyword("mountain")),
    "river" =>              Radical.new("river",              "KAWA",           24027),
    "work" =>               Radical.new("work",               "TAKUMI",         find_kanji_unicode_from_keyword("craft")),
    "oneself" =>            Radical.new("oneself",            "ONORE",          find_kanji_unicode_from_keyword("stop*short")), # alternative: "self", "sign*of*the*snake"
    "turban" =>             Radical.new("turban",             "HABA",           find_kanji_unicode_from_keyword("towel")),
    "dry" =>                Radical.new("dry",                "HOSHI",          find_kanji_unicode_from_keyword("dry")),
    "short*thread" =>       Radical.new("short*thread",       "ITOGASHIRA",     24186),
    "dotted*cliff" =>       Radical.new("dotted*cliff",       "MADARE",         24191),
    "long*stride" =>        Radical.new("long*stride",        "IN'NYOU",        24308),
    "two*hands" =>          Radical.new("two*hands",          "NIJUUASHI",      24318),
    "ceremony" =>           Radical.new("ceremony",           "SHIKIGAMAE",     24331),
    "bow" =>                Radical.new("bow",                "YUMI",           find_kanji_unicode_from_keyword("bow")),
    "pig's*head" =>         Radical.new("pig's*head",         "KEIGASHIRA",     24440),
    "bristle" =>            Radical.new("bristle",            "SANDUKURI",      24417),
    "step" =>               Radical.new("step",               "GYOUNINBEN'",    24435),
    "heart" =>              Radical.new("heart",              "RISSHINBEN'",    find_kanji_unicode_from_keyword("heart")),
    "spear" =>              Radical.new("spear",              "KANOHOKO",       25096),
    "door" =>               Radical.new("door",               "TOBIRANOTO",     find_kanji_unicode_from_keyword("door")),
    "hand" =>               Radical.new("hand",               "TE",             find_kanji_unicode_from_keyword("hand")),
    "branch" =>             Radical.new("branch",             "SHINYOU",        find_kanji_unicode_from_keyword("branch")),
    "strike" =>             Radical.new("strike",             "NOBUN'",         25909),
    "script" =>             Radical.new("script",             "BUN'",           find_kanji_unicode_from_keyword("sentence")),
    "dipper" =>             Radical.new("dipper",             "TOMASU",         find_kanji_unicode_from_keyword("big*dipper")),
    "axe" =>                Radical.new("axe",                "ONO",            find_kanji_unicode_from_keyword("ax")),
    "way" =>                Radical.new("way",                "HOU",            find_kanji_unicode_from_keyword("direction")),
    "have*not" =>           Radical.new("have*not",           "MUNYOU",         26080),
    "sun" =>                Radical.new("sun",                "NICHI",          find_kanji_unicode_from_keyword("day")),
    "say" =>                Radical.new("say",                "IWAKU",          find_kanji_unicode_from_keyword("sayeth")),
    "moon" =>               Radical.new("moon",               "TSUKI",          find_kanji_unicode_from_keyword("month")),
    "tree" =>               Radical.new("tree",               "KI",             find_kanji_unicode_from_keyword("tree")),
    "yawn" =>               Radical.new("yawn",               "AKUBI",          find_kanji_unicode_from_keyword("lack")),
    "stop" =>               Radical.new("stop",               "TOMERU",         find_kanji_unicode_from_keyword("stop")),
    "death" =>              Radical.new("death",              "GATSUHEN'",      27513),  # alternative: 27514
    "weapon" =>             Radical.new("weapon",             "HOKOTSUKURI",    27571),
    "do*not" =>             Radical.new("do*not",             "HAHA",           27595), # alternatives: "mama"
    "compare" =>            Radical.new("compare",            "KURABERU",       find_kanji_unicode_from_keyword("compare")),
    "fur" =>                Radical.new("fur",                "KE",             find_kanji_unicode_from_keyword("fur")),
    "clan" =>               Radical.new("clan",               "UJI",            find_kanji_unicode_from_keyword("family*name")),
    "steam" =>              Radical.new("steam",              "KIGAMAE",        27668),
    "water" =>              Radical.new("water",              "MIZU",           find_kanji_unicode_from_keyword("water")), # alternatives: 27701, 27706
    "fire" =>               Radical.new("fire",               "HI",             find_kanji_unicode_from_keyword("fire")),  # alternatives: 28780
    "claw" =>               Radical.new("claw",               "TSUME",          find_kanji_unicode_from_keyword("claw")),
    "father" =>             Radical.new("father",             "CHICHI",         find_kanji_unicode_from_keyword("father")),
    "mix" =>                Radical.new("mix",                "KOU",            29243),
    "split*wood" =>         Radical.new("split*wood",         "shouhen'",       29247),  # alternative: 20012
    "slice" =>              Radical.new("slice",              "KATA",           find_kanji_unicode_from_keyword("one-sided")),
    "fang" =>               Radical.new("fang",               "KIBAHEN'",       find_kanji_unicode_from_keyword("tusk")),
    "cow" =>                Radical.new("cow",                "USHI",           find_kanji_unicode_from_keyword("cow")), # alternatives: 29276
    "dog" =>                Radical.new("dog",                "INU",            find_kanji_unicode_from_keyword("dog")), # alternatives: 29357
    "dark" =>               Radical.new("dark",               "GEN'",           find_kanji_unicode_from_keyword("mysterious")),
    "king" =>               Radical.new("king",               "TAMA",           find_kanji_unicode_from_keyword("king")), # alternatives: "jewel", 29578, 
    "melon" =>              Radical.new("melon",              "URI",            find_kanji_unicode_from_keyword("melon")),
    "tile" =>               Radical.new("tile",               "KAWARA",         find_kanji_unicode_from_keyword("tile")),
    "sweet" =>              Radical.new("sweet",              "AMAI",           find_kanji_unicode_from_keyword("sweet")),
    "life" =>               Radical.new("life",               "UMARERU",        find_kanji_unicode_from_keyword("life")),
    "use" =>                Radical.new("use",                "MOCHIIRU",       find_kanji_unicode_from_keyword("utilize")), # alternative: 29993
    "field" =>              Radical.new("field",              "TA",             find_kanji_unicode_from_keyword("rice*field")),
    "bolt*of*cloth" =>      Radical.new("bolt*of*cloth",      "HIKI",           find_kanji_unicode_from_keyword("critters")),
    "sickness" =>           Radical.new("sickness",           "YAMAIDARE",      30098),
    "footsteps" =>          Radical.new("footsteps",          "HATSUGASHIRA",   30326),
    "white" =>              Radical.new("white",              "SHIRO",          find_kanji_unicode_from_keyword("white")),
    "skin" =>               Radical.new("skin",               "KEGAWA",         find_kanji_unicode_from_keyword("pelt")),
    "dish" =>               Radical.new("dish",               "SARA",           find_kanji_unicode_from_keyword("dish")),
    "eye" =>                Radical.new("eye",                "ME",             find_kanji_unicode_from_keyword("eye")),
    "pike" =>               Radical.new("pike",               "MUNOHOKO",       find_kanji_unicode_from_keyword("halberd")),
    "arrow" =>              Radical.new("arrow",              "YA",             find_kanji_unicode_from_keyword("dart")),
    "stone" =>              Radical.new("stone",              "ISHI",           find_kanji_unicode_from_keyword("stone")),
    "altar" =>              Radical.new("altar",              "SHIMESU",        find_kanji_unicode_from_keyword("show")), # alternative: 31035
    "track" =>              Radical.new("track",              "GUUOASHI",       31160),
    "two-branch*tree" =>    Radical.new("two-branch*tree",    "NOGI",           31166),
    "cave" =>               Radical.new("cave",               "ANA",            find_kanji_unicode_from_keyword("hole")),
    "stand" =>              Radical.new("stand",              "TATSU",          find_kanji_unicode_from_keyword("stand*up")),
    "bamboo" =>             Radical.new("bamboo",             "TAKE",           find_kanji_unicode_from_keyword("bamboo")), # alternative: 
    "rice" =>               Radical.new("rice",               "KOME",           find_kanji_unicode_from_keyword("rice")),
    "thread" =>             Radical.new("thread",             "ITO",            find_kanji_unicode_from_keyword("thread")), # alternative: 31993
    "can" =>                Radical.new("can",                "KAN'",           find_kanji_unicode_from_keyword("tin*can")),
    "net" =>                Radical.new("net",                "AMIGASHIRA",     32594),
    "sheep" =>              Radical.new("sheep",              "HITSUJI",        find_kanji_unicode_from_keyword("sheep")),  # alternatives: 
    "feather" =>            Radical.new("feather",            "HANE",           find_kanji_unicode_from_keyword("feathers")),
    "old" =>                Radical.new("old",                "ROU",            32770),  # alternatives: "old man"
    "rake" =>               Radical.new("rake",               "SHIKASHITE",     find_kanji_unicode_from_keyword("and*then")),
    "plow" =>               Radical.new("plow",               "RAISUKI",        32786),
    "ear" =>                Radical.new("ear",                "MIMI",           find_kanji_unicode_from_keyword("ear")),
    "brush" =>              Radical.new("brush",              "FUDEDUKURI",     32895), # alternatives: 
    "meat" =>               Radical.new("meat",               "NIKU",           find_kanji_unicode_from_keyword("meat")), # alternatives: "month"
    "minister" =>           Radical.new("minister",           "SHIN'",          find_kanji_unicode_from_keyword("retainer")),
    "mizukara" =>           Radical.new("mizukara",           "MIZUKARA",       find_kanji_unicode_from_keyword("oneself")),
    "arrive" =>             Radical.new("arrive",             "ITARU",          find_kanji_unicode_from_keyword("climax")),
    "mortar" =>             Radical.new("mortar",             "USU",            find_kanji_unicode_from_keyword("mortar")),
    "tongue" =>             Radical.new("tongue",             "SHITA",          find_kanji_unicode_from_keyword("tongue")),
    "opposite" =>           Radical.new("opposite",           "MASU",           33307),
    "boat" =>               Radical.new("boat",               "FUNE",           find_kanji_unicode_from_keyword("boat")),
    "stopping" =>           Radical.new("stopping",           "USHITORA",       33390),
    "colour" =>             Radical.new("colour",             "IRO",            find_kanji_unicode_from_keyword("color")),
    "grass" =>              Radical.new("grass",              "KUSA",           33401),
    "tiger*stripes" =>      Radical.new("tiger*stripes",      "TORAKANMURI",    34281),
    "insect" =>             Radical.new("insect",             "MUSHI",          find_kanji_unicode_from_keyword("insect")),
    "blood" =>              Radical.new("blood",              "CHI",            find_kanji_unicode_from_keyword("blood")),
    "go" =>                 Radical.new("go",                 "GYOU",           find_kanji_unicode_from_keyword("going")),
    "clothes" =>            Radical.new("clothes",            "KOROMO",         find_kanji_unicode_from_keyword("garment")),         # alternative: 34916
    "west" =>               Radical.new("west",               "NISHI",          find_kanji_unicode_from_keyword("west")),            # alternatives: 35198, 35200
    "see" =>                Radical.new("see",                "MIRU",           find_kanji_unicode_from_keyword("see")),
    "horn" =>               Radical.new("horn",               "TSUNO",          find_kanji_unicode_from_keyword("angle")),
    "speech" =>             Radical.new("speech",             "KOTO",           find_kanji_unicode_from_keyword("say")),             # alternatives: 35329
    "valley" =>             Radical.new("valley",             "TANI",           find_kanji_unicode_from_keyword("valley")),
    "bean" =>               Radical.new("bean",               "MAME",           find_kanji_unicode_from_keyword("beans")),
    "pig" =>                Radical.new("pig",                "INOKO",          35925),
    "cat" =>                Radical.new("cat",                "MUJINA",         35960),
    "shell" =>              Radical.new("shell",              "KAI",            find_kanji_unicode_from_keyword("shellfish")),
    "red" =>                Radical.new("red",                "AKA",            find_kanji_unicode_from_keyword("red")),
    "run" =>                Radical.new("run",                "HASHIRU",        find_kanji_unicode_from_keyword("run")),             # alternative: 36209
    "foot" =>               Radical.new("foot",               "ASHI",           find_kanji_unicode_from_keyword("leg")),             # alternative: 
    "body" =>               Radical.new("body",               "MI",             find_kanji_unicode_from_keyword("somebody")),
    "cart" =>               Radical.new("cart",               "KURUMA",         find_kanji_unicode_from_keyword("car")),
    "spicy" =>              Radical.new("spicy",              "KARAI",          find_kanji_unicode_from_keyword("spicy")),
    "morning" =>            Radical.new("morning",            "SHIN'NOTATSU",   find_kanji_unicode_from_keyword("sign*of*the*dragon")),
    "walk" =>               Radical.new("walk",               "SHIN'NYUU",      36789),                                              # alternative: 36790
    "town" =>               Radical.new("town",               "MURA",           38429),                                              # alternatives: "city walls"
    "sake" =>               Radical.new("sake",               "TORI",           find_kanji_unicode_from_keyword("sign*of*the*bird")),
    "divide" =>             Radical.new("divide",             "NOGOME",         37318),
    "village" =>            Radical.new("village",            "SATO",           find_kanji_unicode_from_keyword("ri")),
    "metal" =>              Radical.new("metal",              "KANE",           find_kanji_unicode_from_keyword("gold")),            # alternative: 37330
    "long" =>               Radical.new("long",               "CHOU",           find_kanji_unicode_from_keyword("long")),            # alternative: 38264
    "gate" =>               Radical.new("gate",               "MON'",           find_kanji_unicode_from_keyword("gates")),
    "mound" =>              Radical.new("mound",              "GIFUNOFU",       38429),                                              # alternatives: "large hill"
    "slave" =>              Radical.new("slave",              "REIDUKURI",      38582),
    "old*bird" =>           Radical.new("old*bird",           "FURUTORI",       38585),
    "rain" =>               Radical.new("rain",               "AME",            find_kanji_unicode_from_keyword("rain")),            # alternative: 
    "green" =>              Radical.new("green",              "AO",             find_kanji_unicode_from_keyword("blue")),            # alternative: 38737
    "wrong" =>              Radical.new("wrong",              "ARAZU",          find_kanji_unicode_from_keyword("un-")),
    "face" =>               Radical.new("face",               "MEN'",           find_kanji_unicode_from_keyword("mask")),            # alternative: 38755
    "leather" =>            Radical.new("leather",            "KAKUNOKAWA",     find_kanji_unicode_from_keyword("leather")),
    "tanned*leather" =>     Radical.new("tanned*leather",     "NAMESHIGAWA",    38859),
    "leek" =>               Radical.new("leek",               "NIRA",           38893),
    "sound" =>              Radical.new("sound",              "OTO",            find_kanji_unicode_from_keyword("sound")),
    "big*shell" =>          Radical.new("big*shell",          "OOGAI",          find_kanji_unicode_from_keyword("page")),
    "wind" =>               Radical.new("wind",               "KAZE",           find_kanji_unicode_from_keyword("wind")),            # alternative: 
    "fly" =>                Radical.new("fly",                "TOBU",           find_kanji_unicode_from_keyword("fly")),
    "eat" =>                Radical.new("eat",                "shoku",          find_kanji_unicode_from_keyword("eat")),             # alternative: 39136
    "neck" =>               Radical.new("neck",               "KUBI",           find_kanji_unicode_from_keyword("neck")),
    "fragrant" =>           Radical.new("fragrant",           "NIOIKOU",        find_kanji_unicode_from_keyword("incense")),
    "horse" =>              Radical.new("horse",              "UMA",            find_kanji_unicode_from_keyword("horse")),
    "bone" =>               Radical.new("bone",               "HONE",           find_kanji_unicode_from_keyword("skeleton")),
    "tall" =>               Radical.new("tall",               "TAKAI",          find_kanji_unicode_from_keyword("tall")),            # alternative: 39641
    "hair" =>               Radical.new("hair",               "KAMIGASHIRA",    39647),
    "fight" =>              Radical.new("fight",              "TOUGAMAE",       39717),
    "herbs" =>              Radical.new("herbs",              "chou",           39727),
    "tripod" =>             Radical.new("tripod",             "KANAE",          39370),
    "ghost" =>              Radical.new("ghost",              "ONI",            find_kanji_unicode_from_keyword("ghost")),
    "fish" =>               Radical.new("fish",               "UO",             find_kanji_unicode_from_keyword("fish")),
    "bird" =>               Radical.new("bird",               "TORI",           find_kanji_unicode_from_keyword("bird")),
    "salt" =>               Radical.new("salt",               "RO",             find_kanji_unicode_from_keyword("rocksalt")),
    "deer" =>               Radical.new("deer",               "SHIKA",          find_kanji_unicode_from_keyword("deer")),
    "wheat" =>              Radical.new("wheat",              "MUGI",           find_kanji_unicode_from_keyword("barley")),          # alternative: 40613
    "hemp" =>               Radical.new("hemp",               "ASA",            find_kanji_unicode_from_keyword("hemp")),
    "yellow" =>             Radical.new("yellow",             "KIIRU",          find_kanji_unicode_from_keyword("yellow")),          # alternative: 40643
    "millet" =>             Radical.new("millet",             "KIBI",           40643),
    "black" =>              Radical.new("black",              "KUROU",          find_kanji_unicode_from_keyword("black")),           # alternative: 40657
    "embroidery" =>         Radical.new("embroidery",         "FUTSU",          400697),
    "frog" =>               Radical.new("frog",               "BEN'",           40701),
    "sacrificial*tripod" => Radical.new("sacrificial*tripod", "KANAE",          find_kanji_unicode_from_keyword("tripod")),
    "drum" =>               Radical.new("drum",               "TSUDUMI",        find_kanji_unicode_from_keyword("drum")),
    "rat" =>                Radical.new("rat",                "NEZUMI",         find_kanji_unicode_from_keyword("mouse")),
    "nose" =>               Radical.new("nose",               "HANA",           find_kanji_unicode_from_keyword("nose")),
    "even" =>               Radical.new("even",               "SEI",            40778),
    "tooth" =>              Radical.new("tooth",              "HA",             find_kanji_unicode_from_keyword("tooth")),           # alternative: 40786
    "dragon" =>             Radical.new("dragon",             "RYUU",           find_kanji_unicode_from_keyword("dragon")),          # alternative: "dragon (old)"
    "turtle" =>             Radical.new("turtle",             "KAME",           find_kanji_unicode_from_keyword("tortoise")),        # alternative: 40860
    "flute" =>              Radical.new("flute",              "YAKU",           40864),
    }
  end
end

# These common kanji parts are not radicals:
# (state of mind) 24516
# (fingers) 25164

$radical_data = nil
$radical_by_keyword = {} # hash of keyword (as symbol) to radical unicode

def find_radical_unicode_from_keyword(keyword)
  r = RD.instance().radical()[keyword]
  return r.nil?() ? nil : r.unicode()
end

def convert_to_radical(text)

  text.gsub!(%r{['()/a-zA-Z0-9.*-]+}).each() {
    |word|
    result = ""
    code = find_radical_unicode_from_keyword(word.downcase())
    if code.nil?()
      result += "&lt;UNKNOWN RADICAL [#{word}]&gt;"
    else
      result += jp_unicode(code)
    end
    result
  }
  return text.gsub("^", "")
end
