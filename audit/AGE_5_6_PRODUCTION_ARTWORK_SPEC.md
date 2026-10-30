# Age 5–6 production artwork specification

This specification consolidates the 76 visually incomplete lesson rows reported
at baseline into **70 unique semantic concepts**. Reuse is allowed only for the
same meaning: for example, dog is shared across Hindi and Telugu, while Hindi
`चाचा` (paternal uncle) and Telugu `మామ` (maternal uncle) remain separate.

All raster files use a 512 × 512 px transparent WebP master. The exact shared
prompt is:

> Polished soft 3D children's educational illustration for ages 5–6; one
> immediately recognizable subject described by the row's prompt focus;
> centered, entire subject visible, generous transparent margin, soft studio
> light, warm friendly expression where applicable; no embedded text, letters,
> numbers, symbols, border, watermark, unrelated props, or background scene.

For scenes or abstract concepts, the prompt focus explicitly defines the
minimum meaningful scene. Each focus is appended verbatim to the shared prompt.

## Integrated and verified consolidation

| Asset ID / filename | Words (Telugu / Tamil / Hindi / English) | Prompt focus | Lessons | Verification status |
|---|---|---|---|---|
| `vocab-pen` / `te_pen.webp` | కలం / பேனா / कलम / pen | One blue child-safe writing pen. | english-56-004 | Existing asset; semantic and path verified |
| `vocab-pin` / `pin.webp` | పిన్ను / ஊசி முள் / पिन / pin | One sewing pin with a round red head. | english-56-006 | New WebP; visually inspected and path verified |
| `action-sit` / `sit.webp` | కూర్చో / உட்கார் / बैठो / sit | One child sitting cross-legged and reading. | english-56-007 | New WebP; visually inspected and path verified |
| `animal-pig` / `pig.webp` | పంది / பன்றி / सूअर / pig | One friendly standing young pig. | english-56-008 | New WebP; visually inspected and path verified |
| `animal-dog` / `dog.webp` | కుక్క / நாய் / कुत्ता / dog | One friendly standing dog. | hindi-56-004; telugu-56-004 | Existing Age 5–6 WebP; cross-language meaning verified |
| `vehicle-boat` / `boat.png` | పడవ / படகு / नाव / boat | One small simple boat. | hindi-56-013 | Existing asset; semantic and path verified |
| `animal-cow` / `te_cow.webp` | ఆవు / பசு / गाय / cow | One friendly standing cow. | hindi-56-014 | Existing asset; semantic and path verified |
| `nature-sun` / `sun.webp` | సూర్యుడు / சூரியன் / सूरज / sun | One bright friendly sun. | hindi-56-016 | Existing Age 5–6 WebP; semantic and path verified |
| `object-stone` / `ta_stone.webp` | రాయి / கல் / पत्थर / stone | One smooth grey stone. | tamil-56-001 | Existing asset; semantic and path verified |
| `animal-parrot` / `parrot.webp` | చిలుక / கிளி / तोता / parrot | One green parrot, full body. | tamil-56-003; telugu-56-015 | Existing asset; cross-language meaning verified |
| `nature-tree` / `tree.webp` | చెట్టు / மரம் / पेड़ / tree | One leafy green tree. | tamil-56-017 | Existing Age 5–6 WebP; semantic and path verified |
| `animal-elephant` / `te_elephant.webp` | ఏనుగు / யானை / हाथी / elephant | One friendly standing elephant. | hindi-56-020; tamil-56-018 | Existing asset; cross-language meaning verified |
| `animal-cat` / `cat.png` | పిల్లి / பூனை / बिल्ली / cat | One friendly sitting cat. | tamil-56-020 | Existing asset; semantic and path verified |
| `shape-triangle` / `triangle.webp` | త్రిభుజం / முக்கோணம் / त्रिभुज / triangle | One solid colorful equilateral triangle with three clear straight sides. | numbers-56-048 | Pack WebP; geometry, transparency and phone legibility verified |
| `shape-square` / `square.webp` | చతురస్రం / சதுரம் / वर्ग / square | One solid colorful square with four equal sides. | numbers-56-049 | Pack WebP; geometry, transparency and phone legibility verified |
| `shape-rectangle` / `rectangle.webp` | దీర్ఘచతురస్రం / செவ்வகம் / आयत / rectangle | One wide solid colorful rectangle, clearly not a square. | numbers-56-050 | Pack WebP; geometry, transparency and phone legibility verified |
| `shape-circle` / `circle.webp` | వృత్తం / வட்டம் / वृत्त / circle | One solid colorful perfect circle. | numbers-56-051 | Pack WebP; geometry, transparency and phone legibility verified |

## Remaining production queue

Every row below is 512 × 512 px and currently `not generated`. It must remain
visually incomplete until the final WebP is visually inspected, native-language
meaning is educator-reviewed where noted, and the asset-path tests pass.

| Asset ID / filename | English description | Words (Telugu / Tamil / Hindi / English) | Prompt focus | Lessons | Verification status |
|---|---|---|---|---|---|
| `person-man` / `man.webp` | Adult man | మనిషి / மனிதன் / आदमी / man | One friendly adult man, waist-up, neutral clothing. | english-56-002 | Not generated |
| `clothing-cap` / `cap.webp` | Cap | టోపీ / தொப்பி / टोपी / cap | One colorful child's baseball-style cap. | english-56-003 | Not generated |
| `animal-pet` / `pet.webp` | Pet | పెంపుడు జంతువు / செல்லப்பிராணி / पालतू जानवर / pet | One child gently caring for a small pet dog; relationship is unmistakable. | english-56-005 | Not generated; educator review for concept clarity |
| `toy-top` / `top.webp` | Spinning top | బొంగరం / பம்பரம் / लट्टू / top | One colorful traditional spinning top. | english-56-010 | Not generated |
| `animal-insect` / `insect.webp` | Small insect or bug | కీటకం / பூச்சி / कीड़ा / bug, insect | One friendly six-legged beetle-like insect, anatomically clear. | english-56-012; hindi-56-003; telugu-56-003 | Not generated; shared meaning verified |
| `color-black` / `black.webp` | Black colour | నలుపు / கருப்பு / काला / black | One matte black paint swatch beside a black crayon, no label. | hindi-56-001 | Not generated; educator review for adjective clarity |
| `object-book` / `book.webp` | Book | పుస్తకం / புத்தகம் / किताब / book | One closed colorful children's picture book with a blank cover. | hindi-56-002 | Not generated |
| `object-garbage` / `garbage.webp` | Garbage or rubbish | చెత్త / குப்பை / कूड़ा / garbage | Small tidy group of recyclable household rubbish beside a bin; clean and non-distressing. | hindi-56-005 | Not generated |
| `food-banana` / `banana.webp` | Banana | అరటి పండు / வாழைப்பழம் / केला / banana | One ripe yellow banana. | hindi-56-006 | Not generated |
| `concept-how` / `how.webp` | “How?” or “what kind?” | ఎలా / எப்படி / कैसा / how, what kind | Child comparing two visibly different objects with a questioning gesture, no question mark. | hindi-56-007 | Not generated; native educator verification required |
| `animal-cuckoo` / `cuckoo.webp` | Asian koel or cuckoo | కోయిల / குயில் / कोयल / cuckoo | One Asian koel bird, full body, accurate dark plumage and red eye. | hindi-56-008 | Not generated; species verification required |
| `animal-crow` / `crow.webp` | Crow | కాకి / காகம் / कौआ / crow | One black house crow, full body, accurate grey neck. | hindi-56-009; telugu-56-001 | Not generated; shared meaning verified |
| `object-comb` / `comb.webp` | Comb | దువ్వెన / சீப்பு / कंघी / comb | One colorful wide-tooth hair comb. | hindi-56-010 | Not generated |
| `object-garland` / `garland.webp` | Flower garland | మాల / மாலை / माला / garland | One looped Indian marigold flower garland. | hindi-56-011 | Not generated; cultural review required |
| `nature-water` / `water.webp` | Drinking water | నీరు / தண்ணீர் / पानी / water | One clear glass of clean water with a small water droplet. | hindi-56-012 | Not generated |
| `nature-cloud` / `cloud.webp` | Cloud | మేఘం / மேகம் / बादल / cloud | One soft white-grey rain cloud, no face. | hindi-56-015 | Not generated |
| `person-paternal-uncle` / `paternal_uncle.webp` | Father's younger brother | బాబాయి / சித்தப்பா / चाचा / paternal uncle | Friendly Indian paternal uncle standing alone, adult male, neutral family clothing. | hindi-56-017 | Not generated; kinship educator verification required |
| `number-three` / `three.webp` | Quantity three | మూడు / மூன்று / तीन / three | Exactly three red apples, separated and fully visible; no numeral. | hindi-56-018 | Not generated; object count verification required |
| `person-king` / `king.webp` | King | రాజు / ராஜா / राजा / king | Friendly storybook Indian king with a simple crown and royal robe. | hindi-56-019 | Not generated; cultural review required |
| `time-morning` / `morning.webp` | Morning | ఉదయం / காலை / सुबह / morning | Sunrise outside a child's window with the child waking and stretching. | numbers-56-052 | Not generated; educator review for time concept |
| `comparison-longer` / `longer.webp` | Longer | పొడవైన / நீளமான / लंबा / longer | Two otherwise identical pencils aligned at one end, one visibly longer; no arrows or text. | numbers-56-053 | Not generated; comparison verification required |
| `money-rupees` / `rupees.webp` | Indian rupees | రూపాయలు / ரூபாய் / रुपये / rupees | Child-safe illustration of generic Indian coins and notes without readable denominations. | numbers-56-054 | Not generated; currency educator review required |
| `nature-forest` / `forest.webp` | Forest | అడవి / காடு / जंगल / forest | Small dense group of varied trees forming a clear forest scene. | tamil-56-002 | Not generated |
| `food-leafy-greens` / `leafy_greens.webp` | Leafy greens | ఆకుకూరలు / கீரை / हरी पत्तेदार सब्ज़ी / leafy greens | Fresh bunch of edible green spinach-like leaves. | tamil-56-004 | Not generated |
| `object-water-pot` / `water_pot.webp` | Traditional pot | కుండ / குடம் / घड़ा / water pot | One clean traditional rounded clay water pot. | tamil-56-005 | Not generated; cultural review required |
| `animal-nest` / `nest.webp` | Bird nest | గూడు / கூடு / घोंसला / nest | One woven bird nest with two plain eggs, no bird. | tamil-56-006 | Not generated |
| `animal-catfish` / `catfish.webp` | Catfish | మాగుర చేప / கெண்டை / मागुर मछली / catfish | One anatomically recognizable catfish with whisker-like barbels, side view. | tamil-56-007 | Not generated; species verification required |
| `place-well` / `well.webp` | Water well | బావి / கேணி / कुआँ / well | One safe traditional stone well with raised wall and bucket. | tamil-56-008 | Not generated; cultural review required |
| `body-hand` / `hand.webp` | Hand | చేయి / கை / हाथ / hand | One open child's hand, palm forward, five fingers accurate. | tamil-56-009 | Not generated; anatomy verification required |
| `object-flag` / `flag.webp` | Flag | జెండా / கொடி / झंडा / flag | One simple blank colorful flag on a short pole; not a national flag. | tamil-56-010 | Not generated |
| `animal-chicken` / `chicken.webp` | Chicken or hen | కోడి / கோழி / मुर्गी / chicken | One friendly adult hen, full body, anatomically clear. | tamil-56-011 | Not generated |
| `person-gowri` / `gowri.webp` | Child named Gowri | గౌరి / கௌரி / गौरी / Gowri | One friendly South Indian girl, full body, everyday clothing, no name label. | tamil-56-012 | Not generated; native educator and representation review required |
| `object-conch` / `conch.webp` | Conch shell | శంఖం / சங்கு / शंख / conch | One white spiral conch shell, accurate opening and ridges. | tamil-56-013 | Not generated |
| `body-head` / `head.webp` | Head | తల / தலை / सिर / head | Friendly child's head and shoulders, clear silhouette, no body cropping ambiguity. | tamil-56-014 | Not generated; anatomy review required |
| `animal-fox` / `fox.webp` | Fox | నక్క / நரி / लोमड़ी / fox | One friendly red fox, full body, bushy tail, anatomically clear. | tamil-56-015 | Not generated |
| `body-tooth` / `tooth.webp` | Tooth | పంటి / பல் / दाँत / tooth | One clean healthy molar tooth, friendly educational rendering, no face. | tamil-56-016 | Not generated; anatomy review required |
| `nature-sky` / `sky.webp` | Sky | ఆకాశం / வானம் / आसमान / sky | Simple blue daytime sky with two small white clouds and a low horizon strip. | tamil-56-019 | Not generated |
| `nature-ray` / `ray.webp` | Ray of light | కిరణం / கதிர் / किरण / ray | One warm sunbeam entering through a window and lighting a small patch. | telugu-56-002 | Not generated; concept clarity review required |
| `food-vegetables` / `vegetables.webp` | Vegetables | కూర / காய்கறி / सब्ज़ियाँ / vegetables | Small group of familiar vegetables: carrot, tomato, eggplant and greens. | telugu-56-005 | Not generated |
| `nature-wave` / `wave.webp` | Water wave | కెరటం / அலை / लहर / wave | One gentle blue ocean wave, isolated curl, non-threatening. | telugu-56-006 | Not generated |
| `food-cake` / `cake.webp` | Cake | కేక్ / கேக் / केक / cake | One small undecorated birthday cake with fruit topping, no candles or text. | telugu-56-007 | Not generated |
| `action-service` / `service.webp` | Helpful service | కైంకర్యం / சேவை / सेवा / service | Child respectfully helping an older adult carry a light basket. | telugu-56-008 | Not generated; native educator verification required |
| `animal-crane` / `crane.webp` | Crane bird | కొంగ / கொக்கு / सारस / crane | One Indian crane-like wading bird, full body, long legs and neck. | telugu-56-009 | Not generated; species verification required |
| `animal-monkey` / `monkey.webp` | Monkey | కోతి / குரங்கு / बंदर / monkey | One friendly Indian macaque-like monkey, full body, natural pose. | telugu-56-010 | Not generated; species review required |
| `action-hug` / `hug.webp` | Hug | కౌగిలి / அணைப்பு / गले लगाना / hug | Two children giving a friendly side hug, both full body, clear consent and warmth. | telugu-56-011 | Not generated; educator review for action clarity |
| `person-maternal-uncle` / `maternal_uncle.webp` | Mother's brother | మామ / மாமா / मामा / maternal uncle | Friendly Indian maternal uncle standing alone, adult male, neutral family clothing. | telugu-56-012 | Not generated; kinship educator verification required |
| `food-milk` / `milk.webp` | Milk | పాలు / பால் / दूध / milk | One clear glass filled with white milk, no package or label. | telugu-56-013 | Not generated |
| `person-father` / `father.webp` | Father | నాన్న / அப்பா / पिता / father | Friendly Indian father standing alone in everyday clothing. | telugu-56-014 | Not generated; representation review required |
| `person-grandfather` / `grandfather.webp` | Grandfather | తాత / தாத்தா / दादा / grandfather | Friendly Indian grandfather standing alone in everyday clothing. | telugu-56-016 | Not generated; representation review required |
| `object-toy` / `toy.webp` | Toy | బొమ్మ / பொம்மை / खिलौना / toy | One colorful child-safe wooden toy train, no letters or numbers. | telugu-56-017 | Not generated |
| `weather-rain` / `rain.webp` | Rain | వాన / மழை / बारिश / rain | Gentle rain falling from one grey cloud onto a small green patch. | telugu-56-018 | Not generated |
| `music-lullaby` / `lullaby.webp` | Lullaby | లాలీ / தாலாட்டு / लोरी / lullaby | Parent softly rocking a sleepy baby; calm night-time cues, no musical symbols. | telugu-56-019 | Not generated; educator review for concept clarity |
| `person-sita` / `sita.webp` | Child named Sita | సీత / சீதா / सीता / Sita | One friendly Indian girl, full body, everyday clothing, no name label or religious depiction. | telugu-56-020 | Not generated; native educator and representation review required |

## Verification protocol

An asset becomes verified only after: (1) the subject matches the row meaning,
(2) object counts, anatomy, species and geometry are correct, (3) no text or
unrelated object is present, (4) transparency and phone-size legibility are
visually checked, (5) the WebP path resolves in Flutter tests, and (6) any row
marked for educator review receives that review. Pronunciation verification is
separate and is never inferred from artwork approval.
