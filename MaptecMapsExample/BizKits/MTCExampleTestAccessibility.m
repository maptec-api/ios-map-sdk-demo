#import "MTCExampleTestAccessibility.h"

NSString * const MTCExampleTestAccessibilitySettingsButton = @"example_nav_settings_button";
NSString * const MTCExampleTestAccessibilityLanguageToggle = @"example_nav_language_toggle";
NSString * const MTCExampleTestAccessibilityMapView = @"symbol_layer_map_view";
NSString * const MTCExampleTestAccessibilityMarkerCountValueKey = @"marker_count";
NSString * const MTCExampleTestAccessibilityCircleCountValueKey = @"circle_count";
NSString * const MTCExampleTestAccessibilityLineCountValueKey = @"line_count";
NSString * const MTCExampleTestAccessibilityFillCountValueKey = @"fill_count";
NSString * const MTCExampleTestAccessibilityClusterCountValueKey = @"cluster_count";
NSString * const MTCExampleTestAccessibilityClusterHasCluster = @"cluster_has_cluster";
NSString * const MTCExampleTestAccessibilityHeatmapCountValueKey = @"heatmap_count";
NSString * const MTCExampleTestAccessibilityHeatmapHasHeatmaps = @"heatmap_has_heatmaps";
NSString * const MTCExampleTestAccessibilityMapZoomView = @"map_zoom_view";
NSString * const MTCExampleTestAccessibilityMapLogoView = @"map_logo_view";
NSString * const MTCExampleTestAccessibilityMapDayNightView = @"map_day_night_view";
NSString * const MTCExampleTestAccessibilityLevelMarkerZIndex = @"level_marker_z_index";
NSString * const MTCExampleTestAccessibilityUITestingArgument = @"-ui-testing";
NSString * const MTCExampleTestAccessibilityUITestingRoutePrefix = @"-ui-testing-route=";
NSString * const MTCExampleTestAccessibilityUITestingRouteBasicMarker =
    @"-ui-testing-route=OverlayBasicMarkerExampleViewController";
NSString * const MTCExampleTestAccessibilityUITestingRouteBasicCircle =
    @"-ui-testing-route=OverlayBasicCircleExampleViewController";
NSString * const MTCExampleTestAccessibilityUITestingRouteBasicPolyline =
    @"-ui-testing-route=OverlayBasicPolylineExampleViewController";
NSString * const MTCExampleTestAccessibilityUITestingRouteBasicPolygon =
    @"-ui-testing-route=OverlayBasicPolygonExampleViewController";
NSString * const MTCExampleTestAccessibilityUITestingRouteMapGesture =
    @"-ui-testing-route=MTCMapGestureControlViewController";
NSString * const MTCExampleTestAccessibilityOverlayBasicMarkerScreen = @"OverlayBasicMarkerExampleViewController.screen";
NSString * const MTCExampleTestAccessibilityOverlayBasicCircleScreen = @"OverlayBasicCircleExampleViewController.screen";
NSString * const MTCExampleTestAccessibilityOverlayEqualDistanceCircleScreen = @"OverlayEqualDistanceCircleExampleViewController.screen";
NSString * const MTCExampleTestAccessibilityOverlayBasicPolylineScreen = @"OverlayBasicPolylineExampleViewController.screen";
NSString * const MTCExampleTestAccessibilityOverlayGradientPolylineScreen = @"OverlayGradientPolylineExampleViewController.screen";
NSString * const MTCExampleTestAccessibilityOverlayBasicPolygonScreen = @"OverlayBasicPolygonExampleViewController.screen";
NSString * const MTCExampleTestAccessibilityOverlayMarkerAnimationScreen = @"OverlayMarkerAnimationExampleViewController.screen";
NSString * const MTCExampleTestAccessibilityOverlayMarkerMovementScreen = @"OverlayMarkerMovementExampleViewController.screen";
NSString * const MTCExampleTestAccessibilityOverlayMarkerCollisionBehaviorScreen = @"OverlayMarkerCollisionBehaviorExampleViewController.screen";
NSString * const MTCExampleTestAccessibilityOverlayMarkerSdfScreen = @"OverlaySDFColorMarkerExampleViewController.screen";
NSString * const MTCExampleTestAccessibilityMapGestureControlScreen = @"MTCMapGestureControlViewController.screen";
NSString * const MTCExampleTestAccessibilityMapCompassScreen = @"MTCExampleCompassViewController.screen";
NSString * const MTCExampleTestAccessibilityMapScaleScreen = @"MTCExampleScaleBarViewController.screen";
NSString * const MTCExampleTestAccessibilityMapZoomScreen = @"MTCExampleZoomViewController.screen";
NSString * const MTCExampleTestAccessibilityMapLogoScreen = @"MTCExampleLogoViewController.screen";
NSString * const MTCExampleTestAccessibilityMapDayNightScreen = @"MTCExampleDayNightViewController.screen";
NSString * const MTCExampleTestAccessibilityMapGestureCoordinationScreen = @"MTCMapGestureCoordinationViewController.screen";
NSString * const MTCExampleTestAccessibilityMapGestureThresholdScreen = @"MTCMapGestureResistanceThresholdViewController.screen";
NSString * const MTCExampleTestAccessibilityMapAddScreen = @"MTCMapAddViewController.screen";
NSString * const MTCExampleTestAccessibilityMapLimitScreen = @"MTCMapLimitViewController.screen";
NSString * const MTCExampleTestAccessibilitySettingsSheetTable = @"example_settings_sheet_table";
NSString * const MTCExampleTestAccessibilityLanguageValueChinese = @"zh";
NSString * const MTCExampleTestAccessibilityLanguageValueEnglish = @"en";

NSString * const MTCExampleTestAccessibilityMapRendered = @"mapRendered";

/// 地图 UI 控件
NSString * const MTCExampleTestAccessibilitySwitchCompassEnabled = @"compass_switch";
NSString * const MTCExampleTestAccessibilitySwitchCompassFadeWhenFacingNorth = @"compass_fade_switch";
NSString * const MTCExampleTestAccessibilityDropdownCompassGravity = @"compass_gravity_dropdown";
NSString * const MTCExampleTestAccessibilityBtnCompassRotateClockwise = @"compass_rotate_button";
NSString * const MTCExampleTestAccessibilityMapCompassView = @"map_compass_view";
NSString * const MTCExampleTestAccessibilitySwitchScaleEnabled = @"switch_scale_enabled";
NSString * const MTCExampleTestAccessibilityDropdownScaleGravity = @"dropdown_scale_gravity";
NSString * const MTCExampleTestAccessibilityMapScaleBar = @"map_scale_bar";
NSString * const MTCExampleTestAccessibilitySwitchZoomEnabled = @"switch_zoom_enabled";
NSString * const MTCExampleTestAccessibilityDropdownZoomGravity = @"textfield_zoom_gravity";
NSString * const MTCExampleTestAccessibilityDropdownLogoGravity = @"dropdown_logo_gravity";
NSString * const MTCExampleTestAccessibilitySwitchDayNightEnabled = @"switch_day_night_enabled";
NSString * const MTCExampleTestAccessibilityDropdownDayNightGravity = @"textfield_day_night_gravity";
NSString * const MTCExampleTestAccessibilityBtnDayNightToggle = @"dayNightModeView";
NSString * const MTCExampleTestAccessibilitySwitchTrafficEnabled = @"switch_traffic_enabled";

/// 地图手势协调与阈值
NSString * const MTCExampleTestAccessibilitySwitchSimultaneousGestures = @"switch_simultaneous_gestures";
NSString * const MTCExampleTestAccessibilityBtnConfirmMutualGestures = @"button_confirm_custom_mutual";
NSString * const MTCExampleTestAccessibilitySliderMoveThreshold = @"slider_move_threshold";
NSString * const MTCExampleTestAccessibilitySliderRotateThreshold = @"slider_rotate_threshold";
NSString * const MTCExampleTestAccessibilitySliderRotateResistance = @"slider_rotate_resistance";
NSString * const MTCExampleTestAccessibilitySliderShoveThreshold = @"slider_shove_threshold";
NSString * const MTCExampleTestAccessibilitySliderShoveResistance = @"slider_shove_resistance";
NSString * const MTCExampleTestAccessibilitySliderDoubleClickDelay = @"slider_double_click_delay";
NSString * const MTCExampleTestAccessibilitySwitchDoubleTapPitchReset = @"switch_double_tap_pitch_reset";
NSString * const MTCExampleTestAccessibilitySliderDoubleTapZoomFactor = @"slider_double_tap_zoom_factor";
NSString * const MTCExampleTestAccessibilitySliderInertialScrollDuration = @"slider_inertial_scroll_duration";
NSString * const MTCExampleTestAccessibilitySliderTwoFingerTapZoomReset = @"slider_two_finger_tap_zoom_reset";
NSString * const MTCExampleTestAccessibilitySliderZoomAnimationDuration = @"slider_zoom_animation_duration";
NSString * const MTCExampleTestAccessibilityDropdownZoomCenterMode = @"dropdown_zoom_center_mode";
NSString * const MTCExampleTestAccessibilityRadioZoomCenterGesture = @"radio_zoom_center_gesture";
NSString * const MTCExampleTestAccessibilityRadioZoomCenterScreen = @"radio_zoom_center_screen";
NSString * const MTCExampleTestAccessibilitySliderRotateBearingMin = @"slider_rotate_bearing_min";
NSString * const MTCExampleTestAccessibilitySliderRotateBearingMax = @"slider_rotate_bearing_max";

/// 基础标记页（MarkerBasicScreen）
NSString * const MTCExampleTestAccessibilitySymbolInputLatLng = @"symbol_input_default_latlng";
NSString * const MTCExampleTestAccessibilitySymbolInputIconSize = @"symbol_input_icon_size";
NSString * const MTCExampleTestAccessibilitySymbolBtnAddByType = @"symbol_btn_add_by_type";
NSString * const MTCExampleTestAccessibilitySymbolBtnAddMarker = @"symbol_btn_add_marker";
NSString * const MTCExampleTestAccessibilitySymbolBtnClearAll = @"symbol_btn_clear_all";
NSString * const MTCExampleTestAccessibilitySymbolBtnStopAllAnimations = @"symbol_btn_stop_all_animations";
NSString * const MTCExampleTestAccessibilitySymbolLayerHasMarkers = @"symbol_layer_has_markers";

/// Marker 动画与 SDF 标记
NSString * const MTCExampleTestAccessibilityAnimBtnEnterStart = @"anim_btn_enter_start";
NSString * const MTCExampleTestAccessibilityAnimBtnEnterEnd = @"anim_btn_enter_end";
NSString * const MTCExampleTestAccessibilityAnimBtnDisappearStart = @"anim_btn_disappear_start";
NSString * const MTCExampleTestAccessibilityAnimBtnDisappearEnd = @"anim_btn_disappear_end";
NSString * const MTCExampleTestAccessibilityAnimDropdownEnter = @"anim_dropdown_enter";
NSString * const MTCExampleTestAccessibilityAnimDropdownSelect = @"anim_dropdown_select";
NSString * const MTCExampleTestAccessibilityAnimDropdownDisappear = @"anim_dropdown_disappear";
NSString * const MTCExampleTestAccessibilitySymbolInputSdfIconColor = @"symbol_input_sdf_icon_color";
NSString * const MTCExampleTestAccessibilitySymbolBtnAddSdf = @"symbol_btn_add_sdf";
NSString * const MTCExampleTestAccessibilityMarkerMovementStartButton = @"marker_movement_start_button";

/// 圆形覆盖物（CircleBasicScreen 等）
NSString * const MTCExampleTestAccessibilityCircleInputLatLng = @"circle_input_latlng";
NSString * const MTCExampleTestAccessibilityCircleDrawButton = @"circle_draw_button";
NSString * const MTCExampleTestAccessibilityCircleClearButton = @"circle_clear_button";
NSString * const MTCExampleTestAccessibilityCircleHasCircles = @"circle_has_circles";
NSString * const MTCExampleTestAccessibilityCircleSwitchGeodesic = @"circle_switch_geodesic";
NSString * const MTCExampleTestAccessibilityCircleSwitchDraggable = @"circle_switch_draggable";
NSString * const MTCExampleTestAccessibilityCircleSwitchInnerShadow = @"circle_switch_inner_shadow";
NSString * const MTCExampleTestAccessibilityCircleSwitchOuterGlow = @"circle_switch_outer_glow";

/// 折线覆盖物（PolylineBasicScreen 等）
NSString * const MTCExampleTestAccessibilityLineButtonDraw = @"line_button_draw";
NSString * const MTCExampleTestAccessibilityLineHasLines = @"line_has_lines";
NSString * const MTCExampleTestAccessibilityLineSwitchClosed = @"line_switch_closed";
NSString * const MTCExampleTestAccessibilityLineSwitchDraggable = @"line_switch_draggable";
NSString * const MTCExampleTestAccessibilityLineDropdownStartCap = @"line_dropdown_start_cap";
NSString * const MTCExampleTestAccessibilityLineDropdownEndCap = @"line_dropdown_end_cap";

/// 多边形覆盖物（PolygonBasicScreen）
NSString * const MTCExampleTestAccessibilityFillInputCoordinates = @"fill_input_coordinates";
NSString * const MTCExampleTestAccessibilityFillInputColor = @"fill_input_color";
NSString * const MTCExampleTestAccessibilityFillInputOutlineColor = @"fill_input_outline_color";
NSString * const MTCExampleTestAccessibilityFillDrawButton = @"fill_draw_button";
NSString * const MTCExampleTestAccessibilityFillHasFills = @"fill_has_fills";
NSString * const MTCExampleTestAccessibilityFillSwitchDraggable = @"fill_switch_draggable";

/// 地图手势（MapGestureScreen）
NSString * const MTCExampleTestAccessibilitySwitchAllGesture = @"switch_all_gesture";
NSString * const MTCExampleTestAccessibilitySwitchScrollGesture = @"switch_scroll_gesture";
NSString * const MTCExampleTestAccessibilitySwitchRotateGesture = @"switch_rotate_gesture";
NSString * const MTCExampleTestAccessibilitySwitchTiltGesture = @"switch_tilt_gesture";
NSString * const MTCExampleTestAccessibilitySwitchDoubleFingerZoomGesture = @"switch_double_finger_zoom_gesture";
NSString * const MTCExampleTestAccessibilitySwitchDoubleClickZoomGesture = @"switch_double_click_zoom_gesture";

/// 新增页面 Screen 标识
NSString * const MTCExampleTestAccessibilityMapStyleScreen = @"MTCMapStyleViewController.screen";
NSString * const MTCExampleTestAccessibilityMapTrafficScreen = @"MTCRouteConditionViewController.screen";
NSString * const MTCExampleTestAccessibilityMapLocationScreen = @"MTCMapLocationLayerController.screen";
NSString * const MTCExampleTestAccessibilityMapPoisScreen = @"MTCMapPOIsViewController.screen";
NSString * const MTCExampleTestAccessibilityHeatmapBasicsScreen = @"MTCHeatmapBasicsViewController.screen";
NSString * const MTCExampleTestAccessibilityPointClusterScreen = @"OverlayBasicClusterExampleViewController.screen";
NSString * const MTCExampleTestAccessibilityFloatInfoSimpleScreen = @"MTCFloatInfoSimpleViewController.screen";
NSString * const MTCExampleTestAccessibilityOverlayLevelScreen = @"OverlayLevelExampleViewController.screen";
NSString * const MTCExampleTestAccessibilityWebNearbySearchScreen = @"MTCWebNearbySearchViewController.screen";
NSString * const MTCExampleTestAccessibilityWebInputTipsScreen = @"MTCWebInputTipsViewController.screen";
NSString * const MTCExampleTestAccessibilityWebLocationDetailScreen = @"MTCWebLocationDetailViewController.screen";
NSString * const MTCExampleTestAccessibilityWebAlongSearchScreen = @"MTCWebAlongSearchViewController.screen";
NSString * const MTCExampleTestAccessibilityWebGeoCodingScreen = @"MTCWebGeoCodingViewController.screen";
NSString * const MTCExampleTestAccessibilityWebReverseGeoCodingScreen = @"MTCWebReverseGeoCodingViewController.screen";
NSString * const MTCExampleTestAccessibilityMapRouteScreen = @"MTCMapRouteViewController.screen";

NSString * const MTCExampleTestAccessibilityMapGestureInertialScrollDurationScreen = @"MTCMapGestureInertialScrollDurationViewController.screen";
NSString * const MTCExampleTestAccessibilityMapGestureTwoFingerTapZoomResetScreen = @"MTCMapGestureTwoFingerTapZoomResetViewController.screen";
NSString * const MTCExampleTestAccessibilityMapGestureDoubleTapZoomFactorScreen = @"MTCMapGestureDoubleTapZoomFactorViewController.screen";
NSString * const MTCExampleTestAccessibilityMapGestureDoubleTapDelayScreen = @"MTCMapGestureDoubleClickDelayViewController.screen";
NSString * const MTCExampleTestAccessibilityMapGestureDoubleTapTiltResetScreen = @"MTCMapGestureDoubleTapPitchResetViewController.screen";
NSString * const MTCExampleTestAccessibilityMapGestureRotateBearingRangeScreen = @"MTCMapGestureRotateBearingRangeViewController.screen";
NSString * const MTCExampleTestAccessibilityMapGestureZoomCenterModeScreen = @"MTCMapGestureZoomCenterModeViewController.screen";
NSString * const MTCExampleTestAccessibilityMapGestureZoomAnimationDurationScreen = @"MTCMapGestureZoomAnimationDurationViewController.screen";

/// 地图风格与路况
NSString * const MTCExampleTestAccessibilityStyleLightButton = @"style_light_button";
NSString * const MTCExampleTestAccessibilityStyleDarkButton = @"style_dark_button";
NSString * const MTCExampleTestAccessibilitySwitchMapStyle = @"switch_map_style";
NSString * const MTCExampleTestAccessibilityTextCurrentZoom = @"text_current_zoom";

/// 定位与 POI
NSString * const MTCExampleTestAccessibilitySwitchLocationComponentEnabled = @"switch_location_component_enabled";
NSString * const MTCExampleTestAccessibilitySliderAccuracyAlpha = @"slider_accuracy_alpha";
NSString * const MTCExampleTestAccessibilityDropdownCameraMode = @"dropdown_camera_mode";
NSString * const MTCExampleTestAccessibilityDropdownRenderMode = @"dropdown_render_mode";
NSString * const MTCExampleTestAccessibilityPoiCenterSwitch = @"poi_center_switch";
NSString * const MTCExampleTestAccessibilityPoiClearButton = @"poi_clear_button";

/// 热力图与点聚合
NSString * const MTCExampleTestAccessibilityHeatmapSliderRadius = @"heatmap_slider_radius";
NSString * const MTCExampleTestAccessibilityHeatmapSliderWeight = @"heatmap_slider_weight";
NSString * const MTCExampleTestAccessibilityHeatmapSliderIntensity = @"heatmap_slider_intensity";
NSString * const MTCExampleTestAccessibilityHeatmapSliderOpacity = @"heatmap_slider_opacity";
NSString * const MTCExampleTestAccessibilityHeatmapSliderMinZoom = @"heatmap_slider_min_zoom";
NSString * const MTCExampleTestAccessibilityHeatmapSliderMaxZoom = @"heatmap_slider_max_zoom";
NSString * const MTCExampleTestAccessibilityHeatmapDrawButton = @"heatmap_draw_button";

NSString * const MTCExampleTestAccessibilityPointClusterSliderRadius = @"point_cluster_slider_radius";
NSString * const MTCExampleTestAccessibilityPointClusterSliderMaxZoom = @"point_cluster_slider_max_zoom";
NSString * const MTCExampleTestAccessibilityPointClusterSliderMinPoints = @"point_cluster_slider_min_points";
NSString * const MTCExampleTestAccessibilityPointClusterSwitchEnable = @"point_cluster_switch_enable";
NSString * const MTCExampleTestAccessibilityPointClusterSwitchAbbreviate = @"point_cluster_switch_abbreviate";
NSString * const MTCExampleTestAccessibilityPointClusterSwitchVisible = @"point_cluster_switch_visible";
NSString * const MTCExampleTestAccessibilityPointClusterDrawButton = @"point_cluster_draw_button";
NSString * const MTCExampleTestAccessibilityPointClusterRemoveButton = @"point_cluster_remove_button";

/// 气泡窗与层级
NSString * const MTCExampleTestAccessibilityInfoBtnShowPopup = @"info_btn_show_popup";
NSString * const MTCExampleTestAccessibilityInfoBtnDismiss = @"info_btn_dismiss";
NSString * const MTCExampleTestAccessibilityInfoWindowBubble = @"markerview_bubble";
NSString * const MTCExampleTestAccessibilityLevelBtnMoveUp = @"level_btn_move_up";
NSString * const MTCExampleTestAccessibilityLevelBtnMoveDown = @"level_btn_move_down";

/// 地图事件（MapEventListenerScreen）
NSString * const MTCExampleTestAccessibilityMapEventScreen = @"MTCMapEventListViewController.screen";
NSString * const MTCExampleTestAccessibilitySwitchCameraMove = @"switch_camera_move";
NSString * const MTCExampleTestAccessibilitySwitchMapLongClick = @"switch_map_long_click";
NSString * const MTCExampleTestAccessibilitySwitchFling = @"switch_fling";
NSString * const MTCExampleTestAccessibilitySwitchCameraIdle = @"switch_camera_idle";
NSString * const MTCExampleTestAccessibilitySwitchCameraMoveStarted = @"switch_camera_move_started";
NSString * const MTCExampleTestAccessibilitySwitchMapClick = @"switch_map_click";
NSString * const MTCExampleTestAccessibilityBtnClearLogs = @"btn_clear_logs";

/// 视口与相机控制（MapViewPortScreen）
NSString * const MTCExampleTestAccessibilityMapViewPortScreen = @"MTCMapViewPortController.screen";

/// 限制经纬度显示边界
NSString * const MTCExampleTestAccessibilityMapLimitApplyButton = @"map_limit_apply_button";
NSString * const MTCExampleTestAccessibilityMapLimitClearButton = @"map_limit_clear_button";
NSString * const MTCExampleTestAccessibilityInputPitchMax = @"input_pitch_max";
NSString * const MTCExampleTestAccessibilityInputPitchMin = @"input_pitch_min";
NSString * const MTCExampleTestAccessibilityInputPitchCurrent = @"input_pitch_current";
NSString * const MTCExampleTestAccessibilityInputBearingMax = @"input_bearing_max";
NSString * const MTCExampleTestAccessibilityInputBearingMin = @"input_bearing_min";
NSString * const MTCExampleTestAccessibilityInputBearingCurrent = @"input_bearing_current";
NSString * const MTCExampleTestAccessibilityInputZoomMax = @"input_zoom_max";
NSString * const MTCExampleTestAccessibilityInputZoomMin = @"input_zoom_min";
NSString * const MTCExampleTestAccessibilityInputZoomCurrent = @"input_zoom_current";
NSString * const MTCExampleTestAccessibilityBtnViewPortApply = @"btn_viewport_apply";

/// 鉴权配置（AuthConfigScreen）
NSString * const MTCExampleTestAccessibilityAuthConfigScreen = @"MTCAuthConfigViewController.screen";
NSString * const MTCExampleTestAccessibilityWebAuthStatusScreen = @"MTCWebAuthStatusViewController.screen";
NSString * const MTCExampleTestAccessibilityInputApiKey = @"input_api_key";
NSString * const MTCExampleTestAccessibilityInputSignatureSha1 = @"input_signature_sha1";
NSString * const MTCExampleTestAccessibilityBtnAuthConfirm = @"btn_auth_confirm";

/// 地理围栏（GeofenceScreen）
NSString * const MTCExampleTestAccessibilityGeofenceCircleScreen = @"MTCGEOFencingCircleViewController.screen";
NSString * const MTCExampleTestAccessibilityGeofencePolygonScreen = @"MTCGEOFencingPolygonViewController.screen";
NSString * const MTCExampleTestAccessibilityGeofenceLoadPoint = @"geofence_load_point";
NSString * const MTCExampleTestAccessibilityGeofenceLoadPolygon = @"geofence_load_polygon";
NSString * const MTCExampleTestAccessibilityGeofenceClearAll = @"geofence_clear_all";
NSString * const MTCExampleTestAccessibilityGeofenceClearMarker = @"geofence_clear_marker";
NSString * const MTCExampleTestAccessibilityGeofenceStatus = @"geofence_status";
