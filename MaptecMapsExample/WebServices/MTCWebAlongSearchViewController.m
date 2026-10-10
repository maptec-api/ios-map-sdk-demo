//
//  MTCWebAlongSearchViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/17.
//  Copyright © 2026 ZHOUPanpan. All rights reserved.
//

#import "MTCWebAlongSearchViewController.h"

#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCMTCWebDetailPopupView.h"
#import "MTCTextSearchRequestParams+MTCSupportFork.h"
#import "MTCWebSettingsFloatView.h"
#import "MTCWebSupportUtil.h"

#import <float.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static const CLLocationDegrees MTCAlongSearchDefaultLatitude = 1.3521;
static const CLLocationDegrees MTCAlongSearchDefaultLongitude = 103.8198;
static const double MTCAlongSearchSinglePlaceZoomLevel = 14.0;
static NSString * const MTCAlongSearchDefaultCodedPolyline =
@"1.282650,103.861120\n\
 1.282550,103.861080\n\
 1.281890,103.860820\n\
 1.281760,103.860710\n\
 1.281760,103.860710\n\
 1.281710,103.860670\n\
 1.281690,103.860640\n\
 1.281660,103.860610\n\
 1.281640,103.860520\n\
 1.281750,103.860340\n\
 1.281860,103.860150\n\
 1.281940,103.860210\n\
 1.281920,103.860240\n\
 1.281820,103.860390\n\
 1.281820,103.860470\n\
 1.281830,103.860510\n\
 1.281960,103.860660\n\
 1.282090,103.860720\n\
 1.282270,103.860790\n\
 1.282550,103.860900\n\
 1.282770,103.860980\n\
 1.283490,103.861170\n\
 1.284130,103.861300\n\
 1.284770,103.861400\n\
 1.285010,103.861430\n\
 1.285250,103.861450\n\
 1.285940,103.861440\n\
 1.288040,103.861500\n\
 1.288660,103.861510\n\
 1.290780,103.861550\n\
 1.291050,103.861560\n\
 1.291420,103.861600\n\
 1.291740,103.861670\n\
 1.292050,103.861760\n\
 1.292310,103.861870\n\
 1.292590,103.862020\n\
 1.292930,103.862290\n\
 1.293230,103.862590\n\
 1.293470,103.862910\n\
 1.293580,103.863100\n\
 1.293720,103.863400\n\
 1.293820,103.863730\n\
 1.293910,103.864060\n\
 1.293990,103.864430\n\
 1.294230,103.865730\n\
 1.294360,103.866340\n\
 1.295250,103.870520\n\
 1.295350,103.870870\n\
 1.295420,103.871190\n\
 1.295540,103.872230\n\
 1.295610,103.873440\n\
 1.295770,103.875300\n\
 1.295840,103.875560\n\
 1.295930,103.875750\n\
 1.296050,103.875910\n\
 1.296170,103.876020\n\
 1.296270,103.876090\n\
 1.296360,103.876160\n\
 1.296500,103.876220\n\
 1.296690,103.876300\n\
 1.297190,103.876500\n\
 1.297680,103.876710\n\
 1.298180,103.876920\n\
 1.298530,103.877070\n\
 1.298850,103.877200\n\
 1.299270,103.877370\n\
 1.299440,103.877440\n\
 1.299630,103.877520\n\
 1.299800,103.877630\n\
 1.299970,103.877690\n\
 1.300180,103.877770\n\
 1.300520,103.877890\n\
 1.300770,103.877980\n\
 1.301000,103.878040\n\
 1.301200,103.878090\n\
 1.301380,103.878120\n\
 1.301460,103.878130\n\
 1.301550,103.878140\n\
 1.301680,103.878160\n\
 1.301820,103.878170\n\
 1.301990,103.878180\n\
 1.302130,103.878180\n\
 1.302260,103.878170\n\
 1.302410,103.878170\n\
 1.302500,103.878160\n\
 1.302610,103.878150\n\
 1.302700,103.878140\n\
 1.302830,103.878120\n\
 1.302960,103.878090\n\
 1.303090,103.878060\n\
 1.303220,103.878030\n\
 1.303350,103.878000\n\
 1.303480,103.877960\n\
 1.303690,103.877880\n\
 1.303980,103.877770\n\
 1.304360,103.877630\n\
 1.304830,103.877450\n\
 1.305290,103.877270\n\
 1.305880,103.877040\n\
 1.306220,103.876910\n\
 1.306640,103.876770\n\
 1.306890,103.876660\n\
 1.307430,103.876440\n\
 1.307430,103.876440\n\
 1.307790,103.876310\n\
 1.307980,103.876230\n\
 1.308200,103.876150\n\
 1.308200,103.876150\n\
 1.308310,103.876110\n\
 1.308310,103.876110\n\
 1.308380,103.876080\n\
 1.308570,103.876010\n\
 1.308740,103.875950\n\
 1.308740,103.875950\n\
 1.308860,103.875910\n\
 1.309010,103.875860\n\
 1.309160,103.875810\n\
 1.309310,103.875760\n\
 1.309480,103.875710\n\
 1.309670,103.875650\n\
 1.309770,103.875620\n\
 1.309950,103.875570\n\
 1.309990,103.875560\n\
 1.310200,103.875500\n\
 1.310400,103.875450\n\
 1.310610,103.875390\n\
 1.310840,103.875340\n\
 1.311040,103.875290\n\
 1.311270,103.875240\n\
 1.311480,103.875190\n\
 1.311740,103.875140\n\
 1.311950,103.875100\n\
 1.312150,103.875060\n\
 1.312500,103.875000\n\
 1.312680,103.874980\n\
 1.312880,103.874950\n\
 1.313110,103.874910\n\
 1.313310,103.874890\n\
 1.313430,103.874870\n\
 1.313600,103.874850\n\
 1.313790,103.874830\n\
 1.313980,103.874810\n\
 1.314180,103.874790\n\
 1.314300,103.874770\n\
 1.314520,103.874750\n\
 1.314870,103.874700\n\
 1.315090,103.874680\n\
 1.315180,103.874670\n\
 1.315350,103.874650\n\
 1.315550,103.874630\n\
 1.315730,103.874610\n\
 1.315910,103.874600\n\
 1.316080,103.874590\n\
 1.316250,103.874590\n\
 1.316390,103.874590\n\
 1.316600,103.874600\n\
 1.316800,103.874610\n\
 1.317000,103.874630\n\
 1.317170,103.874650\n\
 1.317350,103.874670\n\
 1.317530,103.874700\n\
 1.317720,103.874740\n\
 1.317900,103.874780\n\
 1.318080,103.874830\n\
 1.318250,103.874880\n\
 1.318420,103.874950\n\
 1.318590,103.875020\n\
 1.318760,103.875090\n\
 1.318860,103.875140\n\
 1.318930,103.875170\n\
 1.319040,103.875240\n\
 1.319090,103.875270\n\
 1.319090,103.875270\n\
 1.319130,103.875290\n\
 1.319240,103.875360\n\
 1.319400,103.875470\n\
 1.319500,103.875550\n\
 1.319680,103.875700\n\
 1.319800,103.875820\n\
 1.319900,103.875920\n\
 1.320020,103.876050\n\
 1.320100,103.876170\n\
 1.320190,103.876280\n\
 1.320300,103.876430\n\
 1.320440,103.876640\n\
 1.320510,103.876770\n\
 1.320570,103.876880\n\
 1.320620,103.876980\n\
 1.320700,103.877130\n\
 1.320750,103.877230\n\
 1.320840,103.877400\n\
 1.320890,103.877490\n\
 1.320960,103.877620\n\
 1.321000,103.877690\n\
 1.321090,103.877870\n\
 1.321190,103.878050\n\
 1.321300,103.878260\n\
 1.321390,103.878430\n\
 1.321450,103.878530\n\
 1.321490,103.878610\n\
 1.321530,103.878700\n\
 1.321600,103.878830\n\
 1.321680,103.878970\n\
 1.321750,103.879100\n\
 1.321810,103.879220\n\
 1.321860,103.879310\n\
 1.321900,103.879380\n\
 1.321960,103.879500\n\
 1.322050,103.879690\n\
 1.322100,103.879780\n\
 1.322150,103.879880\n\
 1.322260,103.880120\n\
 1.322330,103.880290\n\
 1.322420,103.880520\n\
 1.322510,103.880740\n\
 1.322550,103.880840\n\
 1.322600,103.880990\n\
 1.322650,103.881100\n\
 1.322700,103.881220\n\
 1.322750,103.881360\n\
 1.322820,103.881530\n\
 1.322900,103.881750\n\
 1.322960,103.881890\n\
 1.323010,103.882030\n\
 1.323050,103.882130\n\
 1.323150,103.882370\n\
 1.323180,103.882440\n\
 1.323240,103.882580\n\
 1.323330,103.882760\n\
 1.323390,103.882880\n\
 1.323440,103.882980\n\
 1.323480,103.883040\n\
 1.323540,103.883140\n\
 1.323590,103.883210\n\
 1.323640,103.883270\n\
 1.323690,103.883340\n\
 1.323730,103.883400\n\
 1.323820,103.883490\n\
 1.323870,103.883560\n\
 1.323940,103.883620\n\
 1.323990,103.883680\n\
 1.324050,103.883740\n\
 1.324110,103.883790\n\
 1.324190,103.883860\n\
 1.324320,103.883960\n\
 1.324390,103.884010\n\
 1.324450,103.884050\n\
 1.324510,103.884090\n\
 1.324590,103.884140\n\
 1.324660,103.884180\n\
 1.324760,103.884240\n\
 1.324830,103.884270\n\
 1.324910,103.884310\n\
 1.325010,103.884360\n\
 1.325080,103.884390\n\
 1.325180,103.884420\n\
 1.325250,103.884450\n\
 1.325330,103.884480\n\
 1.325390,103.884500\n\
 1.325470,103.884520\n\
 1.325550,103.884540\n\
 1.325640,103.884560\n\
 1.325740,103.884580\n\
 1.325820,103.884590\n\
 1.325890,103.884610\n\
 1.325940,103.884610\n\
 1.325990,103.884620\n\
 1.326040,103.884630\n\
 1.326130,103.884640\n\
 1.326230,103.884660\n\
 1.326320,103.884670\n\
 1.326420,103.884680\n\
 1.326510,103.884690\n\
 1.326640,103.884700\n\
 1.326730,103.884710\n\
 1.326810,103.884730\n\
 1.326870,103.884730\n\
 1.326970,103.884740\n\
 1.327060,103.884750\n\
 1.327130,103.884760\n\
 1.327200,103.884770\n\
 1.327240,103.884770\n\
 1.327280,103.884780\n\
 1.327330,103.884780\n\
 1.327410,103.884790\n\
 1.327510,103.884800\n\
 1.327550,103.884800\n\
 1.327600,103.884810\n\
 1.327650,103.884810\n\
 1.327720,103.884820\n\
 1.327770,103.884830\n\
 1.327800,103.884830\n\
 1.327880,103.884830\n\
 1.327910,103.884840\n\
 1.327970,103.884840\n\
 1.328040,103.884850\n\
 1.328100,103.884850\n\
 1.328180,103.884860\n\
 1.328250,103.884860\n\
 1.328280,103.884860\n\
 1.328320,103.884870\n\
 1.328370,103.884870\n\
 1.328450,103.884880\n\
 1.328540,103.884880\n\
 1.328630,103.884890\n\
 1.328730,103.884890\n\
 1.328820,103.884900\n\
 1.328860,103.884900\n\
 1.328940,103.884900\n\
 1.329020,103.884910\n\
 1.329120,103.884910\n\
 1.329210,103.884910\n\
 1.329330,103.884920\n\
 1.329410,103.884920\n\
 1.329540,103.884930\n\
 1.329630,103.884930\n\
 1.329700,103.884940\n\
 1.329800,103.884950\n\
 1.329850,103.884960\n\
 1.329930,103.884970\n\
 1.329990,103.884980\n\
 1.330060,103.884990\n\
 1.330140,103.885010\n\
 1.330180,103.885020\n\
 1.330250,103.885040\n\
 1.330320,103.885060\n\
 1.330370,103.885080\n\
 1.330420,103.885100\n\
 1.330490,103.885130\n\
 1.330560,103.885160\n\
 1.330640,103.885200\n\
 1.330760,103.885270\n\
 1.330830,103.885310\n\
 1.330970,103.885400\n\
 1.331070,103.885480\n\
 1.331180,103.885580\n\
 1.331260,103.885660\n\
 1.331320,103.885720\n\
 1.331380,103.885790\n\
 1.331460,103.885880\n\
 1.331520,103.885970\n\
 1.331610,103.886100\n\
 1.331660,103.886190\n\
 1.331710,103.886270\n\
 1.331770,103.886390\n\
 1.331870,103.886580\n\
 1.331950,103.886720\n\
 1.332020,103.886860\n\
 1.332050,103.886920\n\
 1.332140,103.887080\n\
 1.332190,103.887180\n\
 1.332300,103.887370\n\
 1.332460,103.887650\n\
 1.332590,103.887860\n\
 1.332710,103.888060\n\
 1.332850,103.888290\n\
 1.332980,103.888480\n\
 1.333060,103.888620\n\
 1.333150,103.888750\n\
 1.333210,103.888850\n\
 1.333260,103.888930\n\
 1.333350,103.889060\n\
 1.333440,103.889200\n\
 1.333490,103.889300\n\
 1.333600,103.889470\n\
 1.333650,103.889560\n\
 1.333710,103.889670\n\
 1.333790,103.889810\n\
 1.333840,103.889900\n\
 1.333890,103.889980\n\
 1.333920,103.890050\n\
 1.333980,103.890160\n\
 1.334020,103.890240\n\
 1.334080,103.890360\n\
 1.334180,103.890560\n\
 1.334190,103.890580\n\
 1.334260,103.890780\n\
 1.334330,103.890900\n\
 1.334360,103.890970\n\
 1.334400,103.891060\n\
 1.334440,103.891180\n\
 1.334480,103.891260\n\
 1.334530,103.891380\n\
 1.334560,103.891460\n\
 1.334640,103.891660\n\
 1.334700,103.891800\n\
 1.334770,103.891930\n\
 1.334830,103.892080\n\
 1.334900,103.892210\n\
 1.334990,103.892400\n\
 1.335160,103.892710\n\
 1.335270,103.892910\n\
 1.335380,103.893100\n\
 1.335470,103.893240\n\
 1.335550,103.893350\n\
 1.335630,103.893510\n\
 1.335690,103.893590\n\
 1.335730,103.893660\n\
 1.335750,103.893690\n\
 1.335830,103.893790\n\
 1.335920,103.893870\n\
 1.335980,103.893970\n\
 1.336110,103.894150\n\
 1.336260,103.894350\n\
 1.336430,103.894570\n\
 1.336560,103.894740\n\
 1.336680,103.894890\n\
 1.336740,103.894980\n\
 1.337000,103.895270\n\
 1.337240,103.895540\n\
 1.337370,103.895680\n\
 1.337460,103.895780\n\
 1.337570,103.895890\n\
 1.337630,103.895940\n\
 1.337690,103.896000\n\
 1.337700,103.896020\n\
 1.337850,103.896150\n\
 1.337950,103.896250\n\
 1.338030,103.896320\n\
 1.338160,103.896440\n\
 1.338240,103.896500\n\
 1.338360,103.896600\n\
 1.338520,103.896740\n\
 1.338700,103.896880\n\
 1.338770,103.896930\n\
 1.338890,103.897020\n\
 1.339020,103.897120\n\
 1.339170,103.897220\n\
 1.339260,103.897280\n\
 1.339390,103.897370\n\
 1.339590,103.897500\n\
 1.339700,103.897570\n\
 1.339880,103.897680\n\
 1.340020,103.897770\n\
 1.340130,103.897830\n\
 1.340240,103.897890\n\
 1.340380,103.897960\n\
 1.340470,103.898010\n\
 1.340510,103.898030\n\
 1.340540,103.898050\n\
 1.340690,103.898120\n\
 1.340820,103.898190\n\
 1.341010,103.898270\n\
 1.341220,103.898350\n\
 1.341380,103.898410\n\
 1.341660,103.898500\n\
 1.341660,103.898500\n\
 1.341890,103.898590\n\
 1.342280,103.898720\n\
 1.342440,103.898770\n\
 1.342540,103.898800\n\
 1.342630,103.898830\n\
 1.342720,103.898850\n\
 1.342820,103.898880\n\
 1.342910,103.898900\n\
 1.342990,103.898920\n\
 1.343060,103.898940\n\
 1.343140,103.898950\n\
 1.343240,103.898970\n\
 1.343350,103.898990\n\
 1.343410,103.899000\n\
 1.343490,103.899010\n\
 1.343560,103.899020\n\
 1.343680,103.899040\n\
 1.343760,103.899050\n\
 1.343860,103.899060\n\
 1.344030,103.899070\n\
 1.344140,103.899080\n\
 1.344250,103.899080\n\
 1.344360,103.899080\n\
 1.344460,103.899080\n\
 1.344620,103.899080\n\
 1.344750,103.899070\n\
 1.344840,103.899070\n\
 1.344970,103.899050\n\
 1.345110,103.899040\n\
 1.345280,103.899010\n\
 1.345450,103.898980\n\
 1.345510,103.898970\n\
 1.345580,103.898960\n\
 1.345650,103.898940\n\
 1.345720,103.898930\n\
 1.345800,103.898910\n\
 1.345870,103.898890\n\
 1.345990,103.898860\n\
 1.346080,103.898830\n\
 1.346530,103.898690\n\
 1.346630,103.898670\n\
 1.346710,103.898640\n\
 1.346820,103.898610\n\
 1.346900,103.898590\n\
 1.346970,103.898570\n\
 1.347060,103.898560\n\
 1.347130,103.898540\n\
 1.347200,103.898530\n\
 1.347290,103.898510\n\
 1.347360,103.898500\n\
 1.347380,103.898500\n\
 1.347490,103.898480\n\
 1.347540,103.898470\n\
 1.347580,103.898470\n\
 1.347660,103.898460\n\
 1.347710,103.898460\n\
 1.347780,103.898450\n\
 1.347840,103.898450\n\
 1.347910,103.898440\n\
 1.348020,103.898430\n\
 1.348180,103.898430\n\
 1.348340,103.898430\n\
 1.348570,103.898440\n\
 1.348670,103.898440\n\
 1.348740,103.898450\n\
 1.348860,103.898460\n\
 1.348970,103.898480\n\
 1.349100,103.898500\n\
 1.349270,103.898530\n\
 1.349380,103.898550\n\
 1.349480,103.898570\n\
 1.349640,103.898610\n\
 1.349780,103.898650\n\
 1.349910,103.898690\n\
 1.349980,103.898710\n\
 1.350090,103.898750\n\
 1.350140,103.898770\n\
 1.350200,103.898800\n\
 1.350280,103.898830\n\
 1.350830,103.899050\n\
 1.352030,103.899550\n\
 1.352310,103.899660\n\
 1.352600,103.899780\n\
 1.352900,103.899900\n\
 1.354670,103.900600\n\
 1.354830,103.900670\n\
 1.354940,103.900720\n\
 1.355130,103.900800\n\
 1.355280,103.900870\n\
 1.355440,103.900950\n\
 1.355550,103.901000\n\
 1.355710,103.901080\n\
 1.355970,103.901220\n\
 1.357320,103.901980\n\
 1.359600,103.903180\n\
 1.359920,103.903360\n\
 1.360510,103.903710\n\
 1.361130,103.904050\n\
 1.362350,103.904720\n\
 1.363570,103.905400\n\
 1.364800,103.906020\n\
 1.365090,103.906150\n\
 1.365430,103.906300\n\
 1.365780,103.906440\n\
 1.366460,103.906670\n\
 1.367770,103.907070\n\
 1.367920,103.907140\n\
 1.368100,103.907200\n\
 1.368470,103.907330\n\
 1.369180,103.907560\n\
 1.370590,103.908010\n\
 1.372860,103.908760\n\
 1.373330,103.908920\n\
 1.374610,103.909310\n\
 1.374980,103.909450\n\
 1.375390,103.909630\n\
 1.375780,103.909830\n\
 1.376080,103.910000\n\
 1.376140,103.910040\n\
 1.376220,103.910090\n\
 1.376780,103.910570\n\
 1.377190,103.910970\n\
 1.377620,103.911510\n\
 1.378030,103.912140\n\
 1.378820,103.913240\n\
 1.379010,103.913510\n\
 1.379240,103.913770\n\
 1.379530,103.914010\n\
 1.379840,103.914180\n\
 1.380010,103.914260\n\
 1.380210,103.914320\n\
 1.380480,103.914380\n\
 1.380620,103.914400\n\
 1.380780,103.914410\n\
 1.381070,103.914420\n\
 1.381240,103.914450\n\
 1.381720,103.914510\n\
 1.381800,103.914500\n\
 1.382110,103.914550\n\
 1.382430,103.914620\n\
 1.382840,103.914750\n\
 1.383270,103.914860\n\
 1.383370,103.914880\n\
 1.383710,103.914930\n\
 1.383970,103.914920\n\
 1.384210,103.914900\n\
 1.384470,103.914860\n\
 1.384740,103.914800\n\
 1.385140,103.914650\n\
 1.385360,103.914550\n\
 1.385470,103.914480\n\
 1.385850,103.914250\n\
 1.386080,103.914100\n\
 1.386320,103.913920\n\
 1.386580,103.913720\n\
 1.386700,103.913640\n\
 1.386760,103.913600\n\
 1.386840,103.913580\n\
 1.387060,103.913390\n\
 1.388790,103.911920\n\
 1.389360,103.911430\n\
 1.389800,103.911060\n\
 1.392480,103.908760\n\
 1.392550,103.908690\n\
 1.393040,103.908240\n\
 1.393720,103.907620\n\
 1.394450,103.906860\n\
 1.394750,103.906490\n\
 1.394970,103.906250\n\
 1.395320,103.905860\n\
 1.395650,103.905480\n\
 1.395930,103.905130\n\
 1.396730,103.904000\n\
 1.397480,103.902800\n\
 1.397520,103.902620\n\
 1.397620,103.902380\n\
 1.397810,103.901950\n\
 1.397970,103.901620\n\
 1.398070,103.901420\n\
 1.398110,103.901320\n\
 1.398100,103.901200\n\
 1.398400,103.900520\n\
 1.398970,103.899010\n\
 1.398980,103.898810\n\
 1.399210,103.897780\n\
 1.399240,103.897600\n\
 1.399270,103.897460\n\
 1.399340,103.897110\n\
 1.399350,103.897100\n\
 1.399460,103.896520\n\
 1.399460,103.896310\n\
 1.399440,103.896160\n\
 1.399350,103.896000\n\
 1.399220,103.895870\n\
 1.399100,103.895750\n\
 1.398040,103.895360\n\
 1.398010,103.895360\n\
 1.397450,103.895150\n\
 1.397110,103.895030\n\
 1.396600,103.894850\n\
 1.396440,103.894790\n\
 1.396280,103.894740\n\
 1.396160,103.894690\n\
 1.396050,103.894650\n\
 1.395930,103.894610\n\
 1.395310,103.894370\n\
 1.394880,103.894230\n\
 1.394700,103.894170\n\
 1.393860,103.893890\n\
 1.393710,103.893840\n\
 1.393560,103.893790\n\
 1.393440,103.893740\n\
 1.393490,103.893620\n\
 1.393540,103.893460\n\
 1.393590,103.893300\n\
 1.393910,103.892350\n\
 1.393930,103.892280\n\
 1.393940,103.892270\n\
 1.394060,103.891940\n\
 1.394080,103.891880\n\
 1.394170,103.891570\n\
 1.394210,103.891390\n\
 1.394300,103.890900\n\
 1.394180,103.890680\n\
 1.394080,103.890550\n\
 1.393700,103.890500\n\
 1.393020,103.890380\n\
 1.392980,103.890510\n\
 1.392760,103.891180\n\
 1.392690,103.891400\n\
 1.392510,103.891940\n\
 1.392470,103.891990\n\
 1.392410,103.892000\n\
 1.392210,103.891940";

@interface MTCWebAlongSearchConfigModel : NSObject

@property (nonatomic, copy) NSString *queryText;
@property (nonatomic, copy) NSString *typesText;
@property (nonatomic, assign) NSInteger typesIndex;
@property (nonatomic, copy) NSString *polylineText;
@property (nonatomic, copy) NSString *encodedPolylineText;
@property (nonatomic, copy) NSString *routeBufferMetersText;
@property (nonatomic, copy) NSString *resultLimitText;
@property (nonatomic, copy) NSString *languageText;
@property (nonatomic, copy) NSString *regionText;
@property (nonatomic, copy) NSArray<NSString *> *extraFields;
@property (nonatomic, assign) NSInteger evaluationModeIndex;
@property (nonatomic, assign) NSInteger rankIndex;
@property (nonatomic, assign) BOOL advancedExpanded;

@end

@implementation MTCWebAlongSearchConfigModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _queryText = @"";
        _typesText = @"";
        _typesIndex = 0;
        _polylineText = MTCAlongSearchDefaultCodedPolyline;
        _encodedPolylineText = @"";
        _routeBufferMetersText = @"1000";
        _resultLimitText = @"";
        _languageText = @"zh";
        _regionText = @"";
        _extraFields = @[];
        _evaluationModeIndex = 0;
        _rankIndex = 0;
        _advancedExpanded = NO;
    }
    return self;
}

@end

@interface MTCWebAlongSearchViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) MTCWebSettingsFloatView *floatView;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong, nullable) MTCMTCWebDetailPopupView *popupView;
@property (nonatomic, strong) MTCWebAlongSearchConfigModel *configModel;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL listVisible;
@property (nonatomic, assign) BOOL mapReady;
@property (nonatomic, assign) MTCWebPopupPurpose activePopupPurpose;

@property (nonatomic, strong, nullable) MTCAlongRouteSearchResponse *response;
@property (nonatomic, copy) NSArray<MTCAlongRouteResult *> *results;
@property (nonatomic, copy) NSArray<MTCPlace *> *places;
@property (nonatomic, copy, nullable) NSString *errorMessage;
@property (nonatomic, copy, nullable) NSString *selectedPlaceID;
@property (nonatomic, strong, nullable) MTCPlace *selectedPlace;
@property (nonatomic, copy) NSDictionary<NSString *, MTCMarker *> *placeMarkers;
@property (nonatomic, strong, nullable) MTCPolyline *routePolyline;
@property (nonatomic, copy) NSArray<NSValue *> *routeCoordinates;
@property (nonatomic, assign) BOOL shouldReloadMarkers;

@end

@implementation MTCWebAlongSearchViewController

- (void)dealloc {
}

#pragma mark - Public

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationItems:YES];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityWebAlongSearchScreen;
    self.configModel = [[MTCWebAlongSearchConfigModel alloc] init];
    self.loading = NO;
    self.listVisible = YES;
    self.activePopupPurpose = MTCWebPopupPurposeNone;
    self.results = @[];
    self.places = @[];
    self.placeMarkers = @{};
    self.routeCoordinates = @[];

    [self configureMapView];
    [self configureFloatView];
    [self configureToggleButton];
    [self updateToggleButtonAppearance];
    [self applyLocalizedTexts];
}

#pragma mark - protocol

#pragma mark - Delegate

#pragma mark -- MTCMapViewDelegate

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
    self.mapReady = YES;
    [self reloadMapMarkersFitIfNeeded:YES];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    self.mapReady = YES;
    [self reloadMapMarkersFitIfNeeded:YES];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    self.mapReady = YES;
    [self reloadMapMarkersFitIfNeeded:YES];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didTapOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    MTCMarker *marker = [(id)overlay isKindOfClass:MTCMarker.class] ? (MTCMarker *)overlay : nil;
    if (!marker) {
        return;
    }
    NSString *placeID = [marker.userInfo isKindOfClass:NSString.class] ? (NSString *)marker.userInfo : nil;
    if (placeID.length == 0) {
        return;
    }
    MTCPlace *place = [self placeForIdentifier:placeID];
    if (!place) {
        return;
    }
    if ([self.selectedPlaceID isEqualToString:placeID]) {
        self.selectedPlace = place;
        [self presentPopupWithTitle:[place mtc_displayTitleWithFallbackIndex:NSNotFound]
                                text:[place mtc_detailText]
                             purpose:MTCWebPopupPurposePlaceDetail];
        [self.floatView reloadData];
        [self focusSelectedPlaceIfNeeded];
        return;
    }
    [self selectPlace:place identifier:placeID presentPopup:YES];
}

#pragma mark - Event

- (void)submitRequest {
    if (self.loading) {
        return;
    }

    NSString *query = [self.configModel.queryText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *types = [self.configModel.typesText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *polylineText = [self.configModel.polylineText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (query.length == 0 && types.length == 0) {
        self.errorMessage = [self localizedStringForKey:@"web_along_query_or_type_required"];
        [self.floatView updateSections:[self buildSections]];
        return;
    }
    if (polylineText.length == 0) {
        self.errorMessage = [self localizedStringForKey:@"web_along_polyline_required"];
        [self.floatView updateSections:[self buildSections]];
        return;
    }

    NSString *encodedPolyline = [MTCWebSupportUtil mtc_encodedPolylineFromPolylineText:polylineText];
    NSArray<NSValue *> *routeCoordinates = [self routeCoordinatesFromPolylineText:polylineText];
    if (encodedPolyline.length == 0 || routeCoordinates.count < 2) {
        self.errorMessage = [self localizedStringForKey:@"web_along_polyline_invalid"];
        [self.floatView updateSections:[self buildSections]];
        return;
    }
    self.configModel.encodedPolylineText = encodedPolyline;

    self.loading = YES;
    self.errorMessage = nil;
    self.response = nil;
    self.results = @[];
    self.places = @[];
    self.routeCoordinates = routeCoordinates;
    self.shouldReloadMarkers = YES;
    [self clearSelectionAndDismissPopup];
    [self.floatView updateSections:[self buildSections]];

    MTCAlongRouteSearchRequest *request = [[MTCAlongRouteSearchRequest alloc] init];
    request.query = query.length > 0 ? query : nil;
    request.types = types.length > 0 ? types : nil;
    request.route = [[MTCRouteGeometry alloc] init];
    request.route.encodedPolyline = encodedPolyline;
    request.routeBufferMeters = [self numberFromString:self.configModel.routeBufferMetersText minimum:100 maximum:50000];
    request.evaluationMode = [self evaluationModeForIndex:self.configModel.evaluationModeIndex];
    request.rank = [self rankTypeForIndex:self.configModel.rankIndex];
    request.resultLimit = [self numberFromString:self.configModel.resultLimitText minimum:1 maximum:20];
    request.language = self.configModel.languageText.length > 0 ? self.configModel.languageText : nil;
    request.region = self.configModel.regionText.length > 0 ? self.configModel.regionText : nil;
    request.extraFields = self.configModel.extraFields.count > 0 ? self.configModel.extraFields : nil;

    __weak typeof(self) weakSelf = self;
    [[MTCSearchService sharedService] alongRouteSearchWithRequest:request completion:^(MTCAlongRouteSearchResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.loading = NO;
        strongSelf.response = response;
        strongSelf.errorMessage = error.localizedDescription;
        strongSelf.results = response.results ?: @[];
        strongSelf.places = [strongSelf placesFromResults:strongSelf.results];
        strongSelf.shouldReloadMarkers = YES;
        [strongSelf.floatView updateSections:[strongSelf buildSections]];
        [strongSelf reloadMapMarkersFitIfNeeded:(strongSelf.listVisible == NO)];
    }];
}

- (void)toggleListVisibility {
    self.listVisible = !self.listVisible;
    if (!self.listVisible) {
        [self dismissPopupPreservingSelection:YES];
        [self reloadMapMarkersFitIfNeeded:YES];
    }
    [self updateListVisibilityAnimated:YES];
    [self updateToggleButtonAppearance];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:CGRectZero];
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    [NSLayoutConstraint activateConstraints:@[
        [self.mapView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.mapView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mapView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mapView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCAlongSearchDefaultLatitude, MTCAlongSearchDefaultLongitude)
                            zoomLevel:10.5];
}

- (void)configureFloatView {
    self.floatView = [[MTCWebSettingsFloatView alloc] initWithTitle:self.title sections:[self buildSections]];
    self.floatView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.floatView];
    [NSLayoutConstraint activateConstraints:@[
        [self.floatView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.floatView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.floatView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.floatView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)configureToggleButton {
    self.toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.toggleButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.toggleButton.backgroundColor = UIColor.systemBlueColor;
    self.toggleButton.tintColor = UIColor.whiteColor;
    self.toggleButton.layer.cornerRadius = 26.0;
    self.toggleButton.layer.shadowColor = UIColor.blackColor.CGColor;
    self.toggleButton.layer.shadowOpacity = 0.18;
    self.toggleButton.layer.shadowRadius = 10.0;
    self.toggleButton.layer.shadowOffset = CGSizeMake(0.0, 6.0);
    [self.toggleButton addTarget:self action:@selector(toggleListVisibility) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toggleButton];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.toggleButton.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-16.0],
        [self.toggleButton.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-16.0],
        [self.toggleButton.widthAnchor constraintEqualToConstant:52.0],
        [self.toggleButton.heightAnchor constraintEqualToConstant:52.0],
    ]];
}

- (void)updateToggleButtonAppearance {
    NSString *symbolName = self.listVisible ? @"map.fill" : @"list.bullet";
    [self.toggleButton setImage:[UIImage systemImageNamed:symbolName] forState:UIControlStateNormal];
    self.toggleButton.accessibilityLabel = self.listVisible ? [self localizedStringForKey:@"web_switch_to_map"] : [self localizedStringForKey:@"web_switch_to_list"];
}

- (void)updateListVisibilityAnimated:(BOOL)animated {
    void (^changes)(void) = ^{
        self.floatView.alpha = self.listVisible ? 1.0 : 0.0;
        self.floatView.transform = self.listVisible ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0.0, 20.0);
    };
    void (^completion)(BOOL) = ^(__unused BOOL finished) {
        self.floatView.userInteractionEnabled = self.listVisible;
    };
    self.floatView.userInteractionEnabled = self.listVisible;
    if (animated) {
        [UIView animateWithDuration:0.22 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:changes completion:completion];
    } else {
        changes();
        completion(YES);
    }
}

- (NSArray<MTCWebSettingsSection *> *)buildSections {
    __weak typeof(self) weakSelf = self;
    NSMutableArray<MTCWebSettingsSection *> *sections = [NSMutableArray array];
    [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_request_parameters"]
                                                          items:@[
        [MTCWebSettingsItem textItemWithTitle:@"query"
                                  placeholder:@"hotel"
                                       detail:[self localizedStringForKey:@"web_along_optional_if_type_is_provided"]
                                 keyboardType:UIKeyboardTypeDefault
                                       getter:^NSString *{ return weakSelf.configModel.queryText ?: @""; }
                                       setter:^(NSString *value) { weakSelf.configModel.queryText = value ?: @""; }],
        [MTCWebSettingsItem optionItemWithTitle:@"type"
                                         detail:[self localizedStringForKey:@"web_along_optional_if_query_is_provided"]
                                        options:[MTCWebSupportUtil mtc_poiTypeOptions]
                                         getter:^NSInteger{ return weakSelf.configModel.typesIndex; }
                                         setter:^(NSInteger index) {
            weakSelf.configModel.typesIndex = index;
            weakSelf.configModel.typesText = [MTCWebSupportUtil mtc_poiTypeForIndex:index];
        }],
        [[MTCWebSettingsItem textViewItemWithTitle:@"Polyline"
                                      placeholder:@"lat,lng\\nlat,lng"
                                           detail:[self localizedStringForKey:@"web_along_raw_route_points"]
                                     keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                  accessoryInputs:@[]
                                           getter:^NSString *{ return weakSelf.configModel.polylineText ?: @""; }
                                           setter:^(NSString *value) { weakSelf.configModel.polylineText = value ?: @""; }]
         textViewHeight:80.0],
        [MTCWebSettingsItem actionItemWithTitle:[self localizedStringForKey:@"web_along_encode_polyline"]
                                          style:MTCWebSettingsActionStyleSecondary
                                        handler:^{
            [weakSelf encodePolylineText];
        }],
        [[MTCWebSettingsItem textViewItemWithTitle:@"encodedPolyline"
                                      placeholder:@"encoded polyline"
                                           detail:[self localizedStringForKey:@"web_along_encoded_result_for_demo"]
                                     keyboardType:UIKeyboardTypeASCIICapable
                                  accessoryInputs:@[]
                                           getter:^NSString *{ return weakSelf.configModel.encodedPolylineText ?: @""; }
                                           setter:^(NSString *value) { weakSelf.configModel.encodedPolylineText = value ?: @""; }]
         textViewHeight:80.0],
        [MTCWebSettingsItem textItemWithTitle:@"routeBufferMeters"
                                  placeholder:@"1000"
                                       detail:[self localizedStringForKey:@"web_along_route_buffer_range"]
                                 keyboardType:UIKeyboardTypeNumberPad
                                       getter:^NSString *{ return weakSelf.configModel.routeBufferMetersText ?: @""; }
                                       setter:^(NSString *value) { weakSelf.configModel.routeBufferMetersText = value ?: @""; }],
        [MTCWebSettingsItem optionItemWithTitle:@"evaluationMode"
                                         detail:@"NONE / STANDARD"
                                        options:@[@"NONE", @"STANDARD"]
                                         getter:^NSInteger { return weakSelf.configModel.evaluationModeIndex; }
                                         setter:^(NSInteger index) {
            weakSelf.configModel.evaluationModeIndex = index;
            [weakSelf normalizeRankForEvaluationModeIfNeeded];
            [weakSelf.floatView updateSections:[weakSelf buildSections]];
        }],
        [MTCWebSettingsItem textViewItemWithTitle:@"extraFields"
                                      placeholder:@"aoi,summary"
                                           detail:[self localizedStringForKey:@"web_comma_or_newline_separated"]
                                     keyboardType:UIKeyboardTypeASCIICapable
                                  accessoryInputs:[MTCWebSupportUtil mtc_placeExtraFieldOptions]
                                           getter:^NSString *{
            return [MTCWebSupportUtil mtc_textFromExtraFields:weakSelf.configModel.extraFields];
        } setter:^(NSString *value) {
            weakSelf.configModel.extraFields = [MTCWebSupportUtil mtc_extraFieldsFromText:value ?: @""] ?: @[];
        }],
        [MTCWebSettingsItem actionItemWithTitle:self.configModel.advancedExpanded ? [self localizedStringForKey:@"web_collapse_parameters"] : [self localizedStringForKey:@"web_expand_parameters"]
                                          style:MTCWebSettingsActionStyleSecondary
                                        handler:^{
            weakSelf.configModel.advancedExpanded = !weakSelf.configModel.advancedExpanded;
            [weakSelf.floatView updateSections:[weakSelf buildSections]];
        }],
    ]]];

    if (self.configModel.advancedExpanded) {
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_more_parameters"]
                                                              items:@[
            [MTCWebSettingsItem textItemWithTitle:@"resultLimit"
                                      placeholder:@"1~20"
                                           detail:[self localizedStringForKey:@"web_1_20_default_20"]
                                     keyboardType:UIKeyboardTypeNumberPad
                                           getter:^NSString *{ return weakSelf.configModel.resultLimitText ?: @""; }
                                           setter:^(NSString *value) { weakSelf.configModel.resultLimitText = value ?: @""; }],
            [MTCWebSettingsItem optionItemWithTitle:@"rank"
                                             detail:[self localizedStringForKey:@"web_along_rank_service_default"]
                                            options:[self rankOptionsForEvaluationModeIndex:self.configModel.evaluationModeIndex]
                                             getter:^NSInteger { return [weakSelf normalizedRankIndex]; }
                                             setter:^(NSInteger index) { weakSelf.configModel.rankIndex = index; }],
            [MTCWebSettingsItem textItemWithTitle:@"language"
                                      placeholder:@"zh"
                                           detail:[self localizedStringForKey:@"web_ietf_language_tag_default_zh"]
                                     keyboardType:UIKeyboardTypeASCIICapable
                                           getter:^NSString *{ return weakSelf.configModel.languageText ?: @""; }
                                           setter:^(NSString *value) { weakSelf.configModel.languageText = value ?: @""; }],
            [MTCWebSettingsItem textItemWithTitle:@"region"
                                      placeholder:@"SG"
                                           detail:[self localizedStringForKey:@"web_cctld_2_chars"]
                                     keyboardType:UIKeyboardTypeASCIICapable
                                           getter:^NSString *{ return weakSelf.configModel.regionText ?: @""; }
                                           setter:^(NSString *value) { weakSelf.configModel.regionText = value ?: @""; }],
        ]]];
    }

    [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_actions"]
                                                          items:@[
        [[MTCWebSettingsItem actionItemWithTitle:self.loading ? [self localizedStringForKey:@"web_searching"] : [self localizedStringForKey:@"web_search"]
                                           style:MTCWebSettingsActionStylePrimary
                                         handler:^{
            [weakSelf submitRequest];
        }] enabledWhen:^BOOL{
            NSString *query = [weakSelf.configModel.queryText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            NSString *types = [weakSelf.configModel.typesText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            NSString *polylineText = [weakSelf.configModel.polylineText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            return weakSelf.loading == NO && (query.length > 0 || types.length > 0) && polylineText.length > 0;
        }],
    ]]];

    if (self.errorMessage.length > 0) {
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_error"]
                                                              items:@[
            [MTCWebSettingsItem infoItemWithTitle:@"message" value:^NSString *{
                return weakSelf.errorMessage ?: @"";
            }],
        ]]];
    }

    if (self.results.count > 0) {
        NSMutableArray<MTCWebSettingsItem *> *items = [NSMutableArray array];
        [self.results enumerateObjectsUsingBlock:^(MTCAlongRouteResult * _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
            (void)stop;
            MTCPlace *place = result.place;
            if (!place) {
                return;
            }
            NSString *placeID = [place mtc_identifierWithFallbackIndex:idx];
            NSString *title = [place mtc_displayTitleWithFallbackIndex:idx];
            NSString *summary = [weakSelf routeSummaryForResult:result];
            NSString *preview = [place mtc_previewText];
            NSString *detail = preview.length > 0 ? [NSString stringWithFormat:@"%@\n%@", summary, preview] : summary;
            [items addObject:[MTCWebSettingsItem selectableInfoItemWithTitle:title
                                                                      detail:detail
                                                                       value:^NSString *{
                return summary;
            } selected:^BOOL{
                return [weakSelf.selectedPlaceID isEqualToString:placeID];
            } handler:^{
                [weakSelf selectPlace:place identifier:placeID presentPopup:YES];
            }]];
        }];
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_results"] items:items]];
    }

    if (self.response) {
        NSString *summary = [NSString stringWithFormat:@"results: %@%@",
                             @(self.results.count),
                             self.response.status.length > 0 ? [NSString stringWithFormat:@"\nstatus: %@", self.response.status] : @""];
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_response_json"]
                                                              items:@[
            [MTCWebSettingsItem selectableInfoItemWithTitle:@"raw"
                                                     detail:[self localizedStringForKey:@"web_tap_to_view_full_response_json"]
                                                      value:^NSString *{
                return summary;
            } selected:nil handler:^{
                [weakSelf presentPopupWithTitle:[self localizedStringForKey:@"web_response_json"]
                                            text:[MTCWebSupportUtil mtc_prettyJSONStringFromDictionary:weakSelf.response.rawDictionary ?: @{}]
                                         purpose:MTCWebPopupPurposeResponseRaw];
            }],
        ]]];
    }

    return sections;
}

- (void)encodePolylineText {
    NSString *polylineText = [self.configModel.polylineText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *encodedPolyline = [MTCWebSupportUtil mtc_encodedPolylineFromPolylineText:polylineText];
    if (encodedPolyline.length == 0) {
        self.errorMessage = [self localizedStringForKey:@"web_along_polyline_invalid"];
        [self.floatView updateSections:[self buildSections]];
        return;
    }
    self.configModel.encodedPolylineText = encodedPolyline;
    self.errorMessage = nil;
    [self.floatView updateSections:[self buildSections]];
}

- (void)selectPlace:(MTCPlace *)place identifier:(NSString *)identifier presentPopup:(BOOL)presentPopup {
    if (identifier.length == 0) {
        return;
    }
    NSString *previousIdentifier = self.selectedPlaceID;
    if ([self.selectedPlaceID isEqualToString:identifier] && self.activePopupPurpose == MTCWebPopupPurposeNone) {
        self.selectedPlaceID = nil;
        self.selectedPlace = nil;
        [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:nil];
        [self dismissPopupPreservingSelection:NO];
        [self.floatView reloadData];
        return;
    }

    self.selectedPlaceID = identifier;
    self.selectedPlace = place;
    [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:identifier];
    if (presentPopup) {
        [self presentPopupWithTitle:[place mtc_displayTitleWithFallbackIndex:NSNotFound]
                                text:[place mtc_detailText]
                             purpose:MTCWebPopupPurposePlaceDetail];
    }
    [self.floatView reloadData];
    [self focusSelectedPlaceIfNeeded];
}

- (void)presentPopupWithTitle:(NSString *)title
                         text:(NSString *)text
                      purpose:(MTCWebPopupPurpose)purpose {
    [self dismissPopupWithoutSelectionMutation];
    self.activePopupPurpose = purpose;

    MTCMTCWebDetailPopupView *popupView = [[MTCMTCWebDetailPopupView alloc] initWithFrame:CGRectZero];
    self.popupView = popupView;

    __weak typeof(self) weakSelf = self;
    [popupView presentInView:self.view title:title text:text dismissHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.popupView = nil;
        if (strongSelf.activePopupPurpose == MTCWebPopupPurposePlaceDetail) {
            strongSelf.activePopupPurpose = MTCWebPopupPurposeNone;
            [strongSelf.floatView reloadData];
        } else {
            strongSelf.activePopupPurpose = MTCWebPopupPurposeNone;
        }
    }];
}

- (void)dismissPopupWithoutSelectionMutation {
    if (!self.popupView) {
        return;
    }
    dispatch_block_t dismissHandler = self.popupView.dismissHandler;
    self.popupView.dismissHandler = nil;
    [self.popupView removeFromSuperview];
    self.popupView = nil;
    if (dismissHandler) {
        dismissHandler();
    }
}

- (void)dismissPopupPreservingSelection:(BOOL)preserveSelection {
    [self dismissPopupWithoutSelectionMutation];
    self.activePopupPurpose = MTCWebPopupPurposeNone;
    if (!preserveSelection) {
        self.selectedPlaceID = nil;
        self.selectedPlace = nil;
    }
    [self.floatView reloadData];
}

- (void)clearSelectionAndDismissPopup {
    NSString *previousIdentifier = self.selectedPlaceID;
    self.selectedPlaceID = nil;
    self.selectedPlace = nil;
    [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:nil];
    [self dismissPopupPreservingSelection:NO];
}

- (void)applyMarkerSelectionStateChangeFromIdentifier:(NSString *)previousIdentifier
                                         toIdentifier:(NSString *)currentIdentifier {
    if (!self.mapReady || self.placeMarkers.count == 0) {
        return;
    }

    MTCMarker *previousMarker = previousIdentifier.length > 0 ? self.placeMarkers[previousIdentifier] : nil;
    MTCMarker *currentMarker = currentIdentifier.length > 0 ? self.placeMarkers[currentIdentifier] : nil;
    if (!previousMarker && !currentMarker) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        if (previousMarker && previousMarker != currentMarker) {
            previousMarker.selected = NO;
        }
        if (currentMarker) {
            currentMarker.selected = YES;
        }
    }];
}

- (void)reloadMapMarkersFitIfNeeded:(BOOL)fitIfNeeded {
    if (!self.mapReady) {
        return;
    }
    if (!self.shouldReloadMarkers) {
        if (fitIfNeeded) {
            [self fitRouteAndPlacesIfNeeded];
        }
        return;
    }
    self.shouldReloadMarkers = NO;
    [self.mapView removeAllInfoWindows];
    [self.mapView removeAllOverlays];
    self.routePolyline = nil;

    NSMutableArray<id<MTCOverlay>> *overlays = [NSMutableArray array];
    MTCPolyline *routePolyline = [self routePolylineFromCoordinates:self.routeCoordinates];
    if (routePolyline) {
        self.routePolyline = routePolyline;
        [overlays addObject:routePolyline];
    }

    NSMutableArray<id<MTCOverlay>> *markers = [NSMutableArray array];
    NSMutableDictionary<NSString *, MTCMarker *> *markersByPlaceID = [NSMutableDictionary dictionary];

    [self.places enumerateObjectsUsingBlock:^(MTCPlace * _Nonnull place, NSUInteger idx, BOOL * _Nonnull stop) {
        (void)stop;
        if (!place.latitude || !place.longitude) {
            return;
        }
        NSString *placeID = [place mtc_identifierWithFallbackIndex:idx];
        if (placeID.length == 0) {
            return;
        }
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue);
        MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:coordinate];
        NSString *title = [place mtc_displayTitleWithFallbackIndex:idx];
        marker.userInfo = placeID;
        marker.style = [self defaultMarkerStyle];
        marker.selectedStyle = [self selectedMarkerStyle];
        marker.style.title.text = title;
        marker.selectedStyle.title.text = title;
        marker.selected = [self.selectedPlaceID isEqualToString:placeID];
        marker.zIndex = marker.isSelected ? 100 : 10;
        marker.togglesSelectionOnTap = NO;
        [markers addObject:marker];
        markersByPlaceID[placeID] = marker;
    }];

    self.placeMarkers = markersByPlaceID;
    [overlays addObjectsFromArray:markers];
    if (overlays.count > 0) {
        [self.mapView addOverlays:overlays];
    }
    if (fitIfNeeded) {
        [self fitRouteAndPlacesIfNeeded];
    }
}

- (void)focusSelectedPlaceIfNeeded {
    MTCPlace *selectedPlace = self.selectedPlaceID.length > 0 ? [self placeForIdentifier:self.selectedPlaceID] : nil;
    if (!selectedPlace.latitude || !selectedPlace.longitude) {
        return;
    }

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(selectedPlace.latitude.doubleValue, selectedPlace.longitude.doubleValue);
    [self.mapView setCenterCoordinate:coordinate
                            transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
}

- (void)fitRouteAndPlacesIfNeeded {
    NSArray<NSValue *> *coordinates = [self visibleCoordinates];
    if (coordinates.count == 0) {
        return;
    }
    if (coordinates.count == 1) {
        CLLocationCoordinate2D coordinate = kCLLocationCoordinate2DInvalid;
        [coordinates.firstObject getValue:&coordinate];
        [self.mapView setCenterCoordinate:coordinate
                                zoomLevel:MTCAlongSearchSinglePlaceZoomLevel];
        return;
    }

    CLLocationDegrees minLatitude = DBL_MAX;
    CLLocationDegrees maxLatitude = -DBL_MAX;
    CLLocationDegrees minLongitude = DBL_MAX;
    CLLocationDegrees maxLongitude = -DBL_MAX;

    for (NSValue *value in coordinates) {
        CLLocationCoordinate2D coordinate = kCLLocationCoordinate2DInvalid;
        [value getValue:&coordinate];
        if (!CLLocationCoordinate2DIsValid(coordinate)) {
            continue;
        }
        minLatitude = MIN(minLatitude, coordinate.latitude);
        maxLatitude = MAX(maxLatitude, coordinate.latitude);
        minLongitude = MIN(minLongitude, coordinate.longitude);
        maxLongitude = MAX(maxLongitude, coordinate.longitude);
    }
    if (minLatitude == DBL_MAX || minLongitude == DBL_MAX) {
        return;
    }

    MTCCoordinateBounds bounds = MTCCoordinateBoundsMake(CLLocationCoordinate2DMake(minLatitude, minLongitude),
                                                         CLLocationCoordinate2DMake(maxLatitude, maxLongitude));
    [self.mapView setVisibleCoordinateBounds:bounds
                                 edgePadding:UIEdgeInsetsMake(80.0, 40.0, 160.0, 40.0)
                                  transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
}

- (NSArray<NSValue *> *)visibleCoordinates {
    NSMutableArray<NSValue *> *coordinates = [NSMutableArray arrayWithArray:self.routeCoordinates ?: @[]];
    for (MTCPlace *place in self.places) {
        if (place.latitude && place.longitude) {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue);
            if (CLLocationCoordinate2DIsValid(coordinate)) {
                [coordinates addObject:[NSValue valueWithBytes:&coordinate objCType:@encode(CLLocationCoordinate2D)]];
            }
        }
    }
    return [coordinates copy];
}

- (NSArray<NSValue *> *)routeCoordinatesFromPolylineText:(NSString *)polylineText {
    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@";\n\r"];
    NSArray<NSString *> *segments = [polylineText componentsSeparatedByCharactersInSet:separatorSet];
    NSMutableArray<NSValue *> *coordinates = [NSMutableArray array];
    for (NSString *segment in segments) {
        NSString *trimmed = [segment stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (trimmed.length == 0) {
            continue;
        }
        MTCCoordinate *parsedCoordinate = [MTCCoordinate mtc_coordinateFromString:trimmed];
        if (!parsedCoordinate) {
            return @[];
        }
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(parsedCoordinate.latitude, parsedCoordinate.longitude);
        if (!CLLocationCoordinate2DIsValid(coordinate)) {
            return @[];
        }
        [coordinates addObject:[NSValue valueWithBytes:&coordinate objCType:@encode(CLLocationCoordinate2D)]];
    }
    return [coordinates copy];
}

- (MTCPolyline *)routePolylineFromCoordinates:(NSArray<NSValue *> *)coordinates {
    if (coordinates.count < 2) {
        return nil;
    }
    CLLocationCoordinate2D *buffer = calloc(coordinates.count, sizeof(CLLocationCoordinate2D));
    NSUInteger cursor = 0;
    for (NSValue *value in coordinates) {
        CLLocationCoordinate2D coordinate = kCLLocationCoordinate2DInvalid;
        [value getValue:&coordinate];
        if (CLLocationCoordinate2DIsValid(coordinate)) {
            buffer[cursor++] = coordinate;
        }
    }
    if (cursor < 2) {
        free(buffer);
        return nil;
    }
    MTCPolyline *polyline = [[MTCPolyline alloc] initWithCoordinates:buffer count:cursor];
    free(buffer);
    polyline.clickable = NO;
    polyline.zIndex = 5;
    polyline.style = [self routePolylineStyle];
    return polyline;
}

- (MTCPolylineStyle *)routePolylineStyle {
    MTCPolylineStyle *style = [[MTCPolylineStyle alloc] init];
    style.strokeColor = UIColor.systemBlueColor;
    style.strokeWeight = 6.0;
    style.strokeOpacity = 0.82;
    style.lineJoinType = MTCLineJoinTypeRound;
    style.startLineCapType = MTCLineCapTypeRound;
    style.endLineCapType = MTCLineCapTypeRound;
    style.directionalArrowStyle.enabled = YES;
    style.directionalArrowStyle.type = MTCLineDirectionalArrowTypeChevron;
    style.directionalArrowStyle.color = UIColor.whiteColor;
    style.directionalArrowStyle.edgeInset = 1.0;
    return style;
}

- (MTCMarkerStyle *)defaultMarkerStyle {
    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    style.icon.type = MTCMarkerIconTypeBlueDot;
    return style;
}

- (MTCMarkerStyle *)selectedMarkerStyle {
    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    style.icon.type = MTCMarkerIconTypeRedDot;
    return style;
}

- (MTCPlace *)placeForIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return nil;
    }
    __block MTCPlace *matchedPlace = nil;
    [self.places enumerateObjectsUsingBlock:^(MTCPlace * _Nonnull place, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *placeID = [place mtc_identifierWithFallbackIndex:idx];
        if ([placeID isEqualToString:identifier]) {
            matchedPlace = place;
            *stop = YES;
        }
    }];
    return matchedPlace;
}

- (NSArray<MTCPlace *> *)placesFromResults:(NSArray<MTCAlongRouteResult *> *)results {
    NSMutableArray<MTCPlace *> *places = [NSMutableArray array];
    for (MTCAlongRouteResult *result in results) {
        if (result.place) {
            [places addObject:result.place];
        }
    }
    return [places copy];
}

- (NSNumber *)numberFromString:(NSString *)string minimum:(NSInteger)minimum maximum:(NSInteger)maximum {
    NSInteger value = string.integerValue;
    if (value < minimum || value > maximum) {
        return nil;
    }
    return @(value);
}

- (MTCAlongRouteEvaluationMode)evaluationModeForIndex:(NSInteger)index {
    switch (index) {
        case 1:
            return MTCAlongRouteEvaluationModeStandard;
        case 0:
        default:
            return MTCAlongRouteEvaluationModeNone;
    }
}

- (NSArray<NSString *> *)rankOptionsForEvaluationModeIndex:(NSInteger)evaluationModeIndex {
    NSMutableArray<NSString *> *options = [NSMutableArray arrayWithObjects:
                                           [self localizedStringForKey:@"web_not_set"],
                                           @"RELEVANCE",
                                           @"ROUTE_ORDER",
                                           @"DISTANCE_FROM_ROUTE",
                                           nil];
    if ([self evaluationModeForIndex:evaluationModeIndex] == MTCAlongRouteEvaluationModeStandard) {
        [options addObject:@"ROUTE_DURATION"];
        [options addObject:@"ROUTE_DISTANCE"];
    }
    return [options copy];
}

- (NSInteger)normalizedRankIndex {
    NSArray<NSString *> *options = [self rankOptionsForEvaluationModeIndex:self.configModel.evaluationModeIndex];
    if (self.configModel.rankIndex < 0 || self.configModel.rankIndex >= (NSInteger)options.count) {
        return 0;
    }
    return self.configModel.rankIndex;
}

- (void)normalizeRankForEvaluationModeIfNeeded {
    self.configModel.rankIndex = [self normalizedRankIndex];
}

- (MTCAlongRouteRankType)rankTypeForIndex:(NSInteger)index {
    switch (index) {
        case 1:
            return MTCAlongRouteRankTypeRelevance;
        case 2:
            return MTCAlongRouteRankTypeRouteOrder;
        case 3:
            return MTCAlongRouteRankTypeDistanceFromRoute;
        case 4:
            return MTCAlongRouteRankTypeRouteDuration;
        case 5:
            return MTCAlongRouteRankTypeRouteDistance;
        default:
            return MTCAlongRouteRankTypeUnspecified;
    }
}

- (NSString *)routeSummaryForResult:(MTCAlongRouteResult *)result {
    if (!result.routeRelation) {
        return @"";
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (result.routeRelation.distanceFromRouteMeters != nil) {
        [parts addObject:[NSString stringWithFormat:@"distance: %@ m", result.routeRelation.distanceFromRouteMeters]];
    }
    if (result.routeRelation.routeOffsetMeters != nil) {
        [parts addObject:[NSString stringWithFormat:@"offset: %@ m", result.routeRelation.routeOffsetMeters]];
    }
    if (result.routeRelation.routeProgressRatio != nil) {
        [parts addObject:[NSString stringWithFormat:@"progress: %.2f%%", result.routeRelation.routeProgressRatio.doubleValue * 100.0]];
    }
    if (result.routeEvaluation) {
        NSMutableArray<NSString *> *evaluationParts = [NSMutableArray array];
        if (result.routeEvaluation.estimatedDurationSeconds != nil) {
            [evaluationParts addObject:[NSString stringWithFormat:@"duration: %@ s", result.routeEvaluation.estimatedDurationSeconds]];
        }
        if (result.routeEvaluation.estimatedDistanceMeters != nil) {
            [evaluationParts addObject:[NSString stringWithFormat:@"distance: %@ m", result.routeEvaluation.estimatedDistanceMeters]];
        }
        if (evaluationParts.count > 0) {
            [parts addObject:[evaluationParts componentsJoinedByString:@", "]];
        }
    }
    return parts.count > 0 ? [parts componentsJoinedByString:@"\n"] : @"";
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCWebAlongSearchViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if (self.floatView) {
        [self.floatView updateTitle:self.title];
        [self.floatView updateSections:[self buildSections]];
    }
}

#pragma mark - Getter & Setter

@end
