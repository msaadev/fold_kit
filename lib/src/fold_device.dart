import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'catalog_fetch_stub.dart'
    if (dart.library.io) 'catalog_fetch_io.dart'
    as fetch;

/// Physical form of a device.
enum FoldForm {
  /// Opens like a book (Galaxy Z Fold, Pixel Fold, iPhone Duo).
  book,

  /// Folds top to bottom (Galaxy Z Flip).
  flip,

  /// No hinge: tablets.
  tablet,

  /// No hinge: phones.
  phone,
}

/// One device in the catalog: window sizes in logical pixels and where the
/// fold is. Used by `FoldPreview` and tests; never used for runtime layout.
@immutable
class FoldDevice {
  /// Stable id, e.g. `iphone-duo`.
  final String id;

  /// Marketing name.
  final String name;

  /// Maker.
  final String brand;

  /// `ios` or `android`.
  final String platform;

  /// Physical form.
  final FoldForm form;

  /// Main (inner) display, landscape for book foldables, in logical pixels.
  final Size inner;

  /// Outer (cover) display, or `null`.
  final Size? outer;

  /// The fold on [inner] while half open, or `null` for devices without one.
  final Rect? fold;

  /// Model identifiers that belong to this device (prefix match), e.g.
  /// `iPhone19,4` or `SM-F966`.
  final List<String> modelIds;

  /// Safe area of the outer display (iPhone Duo: the status strip on the right).
  final EdgeInsets outerPadding;

  /// How the numbers were checked: `simulator`, `emulator`, `device` or `spec`.
  final String verified;

  /// Creates a device.
  const FoldDevice({
    required this.id,
    required this.name,
    required this.brand,
    required this.platform,
    required this.form,
    required this.inner,
    this.outer,
    this.fold,
    this.outerPadding = EdgeInsets.zero,
    this.modelIds = const [],
    this.verified = 'spec',
  });

  /// Reads one entry of the `monsware.com/foldkit/models` JSON.
  factory FoldDevice.fromJson(Map<String, dynamic> json) {
    Size size(Object? v) {
      final m = v as Map<String, dynamic>;
      return Size(
        (m['width'] as num).toDouble(),
        (m['height'] as num).toDouble(),
      );
    }

    final inner = size(json['inner']);
    final f = json['fold'] as Map<String, dynamic>?;
    Rect? fold;
    if (f != null) {
      final offset = (f['offset'] as num).toDouble();
      final thickness = (f['thickness'] as num? ?? 0).toDouble();
      fold = f['axis'] == 'horizontal'
          ? Rect.fromLTWH(0, offset, inner.width, thickness)
          : Rect.fromLTWH(offset, 0, thickness, inner.height);
    }
    return FoldDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      form: FoldForm.values.firstWhere(
        (f) => f.name == json['form'],
        orElse: () => FoldForm.phone,
      ),
      inner: inner,
      outer: json['outer'] == null ? null : size(json['outer']),
      fold: fold,
      outerPadding: _insets(json['outerPadding']),
      modelIds: [for (final m in json['modelIds'] as List? ?? const []) '$m'],
      verified: json['verified'] as String? ?? 'spec',
    );
  }

  static EdgeInsets _insets(Object? v) {
    if (v is! Map) return EdgeInsets.zero;
    double side(String k) => (v[k] as num? ?? 0).toDouble();
    return EdgeInsets.fromLTRB(
      side('left'),
      side('top'),
      side('right'),
      side('bottom'),
    );
  }

  @override
  String toString() => 'FoldDevice($id)';
}

/// The device catalog. Ships with a snapshot; [refresh] can pull the latest
/// list from monsware.com so new foldables appear without a package release.
abstract final class FoldDevices {
  /// Where [refresh] reads from by default.
  static final Uri source = Uri.parse('https://monsware.com/foldkit/models');

  /// Schema version this package understands.
  static const int schemaVersion = 1;

  static List<FoldDevice> _all = snapshot;

  /// Every known device (the snapshot until [refresh] succeeds).
  static List<FoldDevice> get all => List.unmodifiable(_all);

  /// The device with [id], or `null`.
  static FoldDevice? byId(String id) {
    for (final d in _all) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// The device whose model id matches [model] (`iPhone19,4`, `SM-F966B`…), or `null`.
  static FoldDevice? byModel(String? model) {
    if (model == null || model.isEmpty) return null;
    for (final d in _all) {
      if (d.modelIds.any(model.startsWith)) return d;
    }
    return null;
  }

  /// Opt-in: downloads the latest catalog (GET only, no data sent; the
  /// request reveals the device's IP address to monsware.com). Keeps the
  /// current list on any error. Returns whether the list was updated.
  /// Does nothing on the web.
  static Future<bool> refresh({Uri? from}) async {
    final body = await fetch.fetchCatalog(from ?? source);
    if (body == null) return false;
    final devices = parse(body);
    if (devices == null || devices.isEmpty) return false;
    _all = devices;
    return true;
  }

  /// Parses catalog JSON; `null` when it is invalid or a newer schema.
  static List<FoldDevice>? parse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['schemaVersion'] != schemaVersion) return null;
      return [
        for (final d in json['devices'] as List)
          FoldDevice.fromJson(d as Map<String, dynamic>),
      ];
    } catch (_) {
      return null;
    }
  }

  /// The catalog shipped with this version of the package.
  static const List<FoldDevice> snapshot = [
    FoldDevice(
      id: 'iphone-duo',
      name: 'iPhone Duo',
      brand: 'Apple',
      platform: 'ios',
      form: FoldForm.book,
      inner: Size(951, 669),
      outer: Size(466, 678),
      fold: Rect.fromLTWH(455.5, 0, 40, 669),
      outerPadding: EdgeInsets.only(right: 84),
      modelIds: ['iPhone19,4'],
      verified: 'simulator',
    ),
    FoldDevice(
      id: 'galaxy-z-fold7',
      name: 'Galaxy Z Fold7',
      brand: 'Samsung',
      platform: 'android',
      form: FoldForm.book,
      inner: Size(832, 750),
      outer: Size(411, 960),
      fold: Rect.fromLTWH(416, 0, 0, 750),
      modelIds: ['SM-F966'],
    ),
    FoldDevice(
      id: 'ipad-mini',
      name: 'iPad mini',
      brand: 'Apple',
      platform: 'ios',
      form: FoldForm.tablet,
      inner: Size(1133, 744),
    ),
    FoldDevice(
      id: 'ipad-11',
      name: 'iPad 11"',
      brand: 'Apple',
      platform: 'ios',
      form: FoldForm.tablet,
      inner: Size(1180, 820),
    ),
    FoldDevice(
      id: 'ipad-pro-13',
      name: 'iPad Pro 13"',
      brand: 'Apple',
      platform: 'ios',
      form: FoldForm.tablet,
      inner: Size(1376, 1032),
    ),
    FoldDevice(
      id: 'iphone-17-pro',
      name: 'iPhone 17 Pro',
      brand: 'Apple',
      platform: 'ios',
      form: FoldForm.phone,
      inner: Size(402, 874),
    ),
  ];
}
