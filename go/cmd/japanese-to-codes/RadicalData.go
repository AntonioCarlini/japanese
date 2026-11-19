package main

// The radical table, taken from the RD class in scripts/RadicalSupport.rb.
//
// To add a radical, add a line to radical_entries below. Order matters only in that
// the entries are looked up (and any unknown-kanji messages are printed) in this order.
//
// Each entry is:   {english, reading, keyword, unicode}
//  - english: the name used in @RD{{...}} (lowercase; spaces are written as '*')
//  - reading: the Japanese reading, in capitals
//  - keyword: if not empty, the code point is looked up in data/kanji.data by this keyword
//  - unicode: otherwise, this code point (decimal)

type radical_entry struct {
	english string
	reading string
	keyword string
	unicode int
}

var radical_entries = []radical_entry{
	{"one", "ICHI", "one", 0},
	{"line", "BOU", "", 20008},
	{"dot", "TEN'", "", 20022},
	{"bend", "NO", "", 20031},
	{"second", "OTSU", "fish*guts", 0}, // alternative 20058
	{"hook", "HANEBOU", "", 20101},
	{"two", "FUTA", "two", 0},
	{"lid", "NABEBUTA", "", 20128},
	{"human", "HITO", "person", 0}, // alternative 20155
	{"legs", "NIN'NYOU", "", 20799},
	{"enter", "IRU", "enter", 0},
	{"eight", "HACHIGASHIRA", "eight", 0},
	{"upside*down*box", "MAKIGAMAE", "", 20866},
	{"cover", "WAKANMURI", "", 20886},
	{"ice", "NISUI", "", 20907},
	{"desk", "TSUKUE", "", 20960},
	{"container", "UKEBAKO", "", 20981},
	{"knife", "KATANA", "sword", 0}, // alternative: 20994,
	{"power", "CHIKARA", "power", 0},
	{"wrap", "TSUTSUMIGAMAE", "", 21241},
	{"spoon", "SAJINOHI", "spoon", 0},
	{"box", "HAKOGAMAE", "", 21274},
	{"dead", "KAKUSHIGAMAE", "deceased", 0}, // alternative: 21304
	{"ten", "JUU", "ten", 0},
	{"divination", "BOKUNOTO", "augury", 0},
	{"seal", "FUSHIDUKURI", "", 21353},
	{"cliff", "GANDARE", "", 21378},
	{"private", "MU", "", 21430},
	{"again", "MATA", "or*again", 0},
	{"mouth", "KUCHI", "mouth", 0},
	{"enclosure", "KUNIGAMAE", "", 22231},
	{"earth", "TSUCHI", "soil", 0},
	{"scholar", "SAMURAI", "gentleman", 0},
	{"winter", "FUYUGASHIRA", "", 22786},
	{"winter*variant", "SUINYOU", "", 22794},
	{"evening", "YUUBE", "evening", 0},
	{"big", "DAI", "large", 0},
	{"woman", "ON'NA", "woman", 0},
	{"child", "KO", "child", 0},
	{"roof", "UKANMURI", "", 23424},
	{"sun*(unit)", "SUN'", "measurement", 0},
	{"small", "CHIISAI", "little", 0},
	{"lame", "MAGEASHI", "", 23586},
	{"corpse", "SHIKABANE", "", 23608},
	{"sprout", "TETSU", "", 23662},
	{"mountain", "YAMA", "mountain", 0},
	{"river", "KAWA", "", 24027},
	{"work", "TAKUMI", "craft", 0},
	{"oneself", "ONORE", "stop*short", 0}, // alternative: "self", "sign*of*the*snake"
	{"turban", "HABA", "towel", 0},
	{"dry", "HOSHI", "dry", 0},
	{"short*thread", "ITOGASHIRA", "", 24186},
	{"dotted*cliff", "MADARE", "", 24191},
	{"long*stride", "IN'NYOU", "", 24308},
	{"two*hands", "NIJUUASHI", "", 24318},
	{"ceremony", "SHIKIGAMAE", "", 24331},
	{"bow", "YUMI", "bow", 0},
	{"pig's*head", "KEIGASHIRA", "", 24440},
	{"bristle", "SANDUKURI", "", 24417},
	{"step", "GYOUNINBEN'", "", 24435},
	{"heart", "RISSHINBEN'", "heart", 0},
	{"spear", "KANOHOKO", "", 25096},
	{"door", "TOBIRANOTO", "door", 0},
	{"hand", "TE", "hand", 0},
	{"branch", "SHINYOU", "branch", 0},
	{"strike", "NOBUN'", "", 25909},
	{"script", "BUN'", "sentence", 0},
	{"dipper", "TOMASU", "big*dipper", 0},
	{"axe", "ONO", "ax", 0},
	{"way", "HOU", "direction", 0},
	{"have*not", "MUNYOU", "", 26080},
	{"sun", "NICHI", "day", 0},
	{"say", "IWAKU", "sayeth", 0},
	{"moon", "TSUKI", "month", 0},
	{"tree", "KI", "tree", 0},
	{"yawn", "AKUBI", "lack", 0},
	{"stop", "TOMERU", "stop", 0},
	{"death", "GATSUHEN'", "", 27513}, // alternative: 27514
	{"weapon", "HOKOTSUKURI", "", 27571},
	{"do*not", "HAHA", "", 27595}, // alternatives: "mama"
	{"compare", "KURABERU", "compare", 0},
	{"fur", "KE", "fur", 0},
	{"clan", "UJI", "family*name", 0},
	{"steam", "KIGAMAE", "", 27668},
	{"water", "MIZU", "water", 0}, // alternatives: 27701, 27706
	{"fire", "HI", "fire", 0},     // alternatives: 28780
	{"claw", "TSUME", "claw", 0},
	{"father", "CHICHI", "father", 0},
	{"mix", "KOU", "", 29243},
	{"split*wood", "shouhen'", "", 29247}, // alternative: 20012
	{"slice", "KATA", "one-sided", 0},
	{"fang", "KIBAHEN'", "tusk", 0},
	{"cow", "USHI", "cow", 0}, // alternatives: 29276
	{"dog", "INU", "dog", 0},  // alternatives: 29357
	{"dark", "GEN'", "mysterious", 0},
	{"king", "TAMA", "king", 0}, // alternatives: "jewel", 29578,
	{"melon", "URI", "melon", 0},
	{"tile", "KAWARA", "tile", 0},
	{"sweet", "AMAI", "sweet", 0},
	{"life", "UMARERU", "life", 0},
	{"use", "MOCHIIRU", "utilize", 0}, // alternative: 29993
	{"field", "TA", "rice*field", 0},
	{"bolt*of*cloth", "HIKI", "critters", 0},
	{"sickness", "YAMAIDARE", "", 30098},
	{"footsteps", "HATSUGASHIRA", "", 30326},
	{"white", "SHIRO", "white", 0},
	{"skin", "KEGAWA", "pelt", 0},
	{"dish", "SARA", "dish", 0},
	{"eye", "ME", "eye", 0},
	{"pike", "MUNOHOKO", "halberd", 0},
	{"arrow", "YA", "dart", 0},
	{"stone", "ISHI", "stone", 0},
	{"altar", "SHIMESU", "show", 0}, // alternative: 31035
	{"track", "GUUOASHI", "", 31160},
	{"two-branch*tree", "NOGI", "", 31166},
	{"cave", "ANA", "hole", 0},
	{"stand", "TATSU", "stand*up", 0},
	{"bamboo", "TAKE", "bamboo", 0}, // alternative:
	{"rice", "KOME", "rice", 0},
	{"thread", "ITO", "thread", 0}, // alternative: 31993
	{"can", "KAN'", "tin*can", 0},
	{"net", "AMIGASHIRA", "", 32594},
	{"sheep", "HITSUJI", "sheep", 0}, // alternatives:
	{"feather", "HANE", "feathers", 0},
	{"old", "ROU", "", 32770}, // alternatives: "old man"
	{"rake", "SHIKASHITE", "and*then", 0},
	{"plow", "RAISUKI", "", 32786},
	{"ear", "MIMI", "ear", 0},
	{"brush", "FUDEDUKURI", "", 32895}, // alternatives:
	{"meat", "NIKU", "meat", 0},        // alternatives: "month"
	{"minister", "SHIN'", "retainer", 0},
	{"mizukara", "MIZUKARA", "oneself", 0},
	{"arrive", "ITARU", "climax", 0},
	{"mortar", "USU", "mortar", 0},
	{"tongue", "SHITA", "tongue", 0},
	{"opposite", "MASU", "", 33307},
	{"boat", "FUNE", "boat", 0},
	{"stopping", "USHITORA", "", 33390},
	{"colour", "IRO", "color", 0},
	{"grass", "KUSA", "", 33401},
	{"tiger*stripes", "TORAKANMURI", "", 34281},
	{"insect", "MUSHI", "insect", 0},
	{"blood", "CHI", "blood", 0},
	{"go", "GYOU", "going", 0},
	{"clothes", "KOROMO", "garment", 0}, // alternative: 34916
	{"west", "NISHI", "west", 0},        // alternatives: 35198, 35200
	{"see", "MIRU", "see", 0},
	{"horn", "TSUNO", "angle", 0},
	{"speech", "KOTO", "say", 0}, // alternatives: 35329
	{"valley", "TANI", "valley", 0},
	{"bean", "MAME", "beans", 0},
	{"pig", "INOKO", "", 35925},
	{"cat", "MUJINA", "", 35960},
	{"shell", "KAI", "shellfish", 0},
	{"red", "AKA", "red", 0},
	{"run", "HASHIRU", "run", 0}, // alternative: 36209
	{"foot", "ASHI", "leg", 0},   // alternative:
	{"body", "MI", "somebody", 0},
	{"cart", "KURUMA", "car", 0},
	{"spicy", "KARAI", "spicy", 0},
	{"morning", "SHIN'NOTATSU", "sign*of*the*dragon", 0},
	{"walk", "SHIN'NYUU", "", 36789}, // alternative: 36790
	{"town", "MURA", "", 38429},      // alternatives: "city walls"
	{"sake", "TORI", "sign*of*the*bird", 0},
	{"divide", "NOGOME", "", 37318},
	{"village", "SATO", "ri", 0},
	{"metal", "KANE", "gold", 0}, // alternative: 37330
	{"long", "CHOU", "long", 0},  // alternative: 38264
	{"gate", "MON'", "gates", 0},
	{"mound", "GIFUNOFU", "", 38429}, // alternatives: "large hill"
	{"slave", "REIDUKURI", "", 38582},
	{"old*bird", "FURUTORI", "", 38585},
	{"rain", "AME", "rain", 0}, // alternative:
	{"green", "AO", "blue", 0}, // alternative: 38737
	{"wrong", "ARAZU", "un-", 0},
	{"face", "MEN'", "mask", 0}, // alternative: 38755
	{"leather", "KAKUNOKAWA", "leather", 0},
	{"tanned*leather", "NAMESHIGAWA", "", 38859},
	{"leek", "NIRA", "", 38893},
	{"sound", "OTO", "sound", 0},
	{"big*shell", "OOGAI", "page", 0},
	{"wind", "KAZE", "wind", 0}, // alternative:
	{"fly", "TOBU", "fly", 0},
	{"eat", "shoku", "eat", 0}, // alternative: 39136
	{"neck", "KUBI", "neck", 0},
	{"fragrant", "NIOIKOU", "incense", 0},
	{"horse", "UMA", "horse", 0},
	{"bone", "HONE", "skeleton", 0},
	{"tall", "TAKAI", "tall", 0}, // alternative: 39641
	{"hair", "KAMIGASHIRA", "", 39647},
	{"fight", "TOUGAMAE", "", 39717},
	{"herbs", "chou", "", 39727},
	{"tripod", "KANAE", "", 39370},
	{"ghost", "ONI", "ghost", 0},
	{"fish", "UO", "fish", 0},
	{"bird", "TORI", "bird", 0},
	{"salt", "RO", "rocksalt", 0},
	{"deer", "SHIKA", "deer", 0},
	{"wheat", "MUGI", "barley", 0}, // alternative: 40613
	{"hemp", "ASA", "hemp", 0},
	{"yellow", "KIIRU", "yellow", 0}, // alternative: 40643
	{"millet", "KIBI", "", 40643},
	{"black", "KUROU", "black", 0}, // alternative: 40657
	{"embroidery", "FUTSU", "", 40697},
	{"frog", "BEN'", "", 40701},
	{"sacrificial*tripod", "KANAE", "tripod", 0},
	{"drum", "TSUDUMI", "drum", 0},
	{"rat", "NEZUMI", "mouse", 0},
	{"nose", "HANA", "nose", 0},
	{"even", "SEI", "", 40778},
	{"tooth", "HA", "tooth", 0},       // alternative: 40786
	{"dragon", "RYUU", "dragon", 0},   // alternative: "dragon (old)"
	{"turtle", "KAME", "tortoise", 0}, // alternative: 40860
	{"flute", "YAKU", "", 40864},
}

// These common kanji parts are not radicals:
// (state of mind) 24516
// (fingers) 25164
