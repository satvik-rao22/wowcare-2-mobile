// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_asset_resolve_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaAssetResolveResponse _$MediaAssetResolveResponseFromJson(
        Map<String, dynamic> json) =>
    MediaAssetResolveResponse(
      data: MediaAssetResolveData.fromAny(json['data']),
    );

MediaAssetResolveData _$MediaAssetResolveDataFromJson(
        Map<String, dynamic> json) =>
    MediaAssetResolveData(
      assets: json['assets'] as List<dynamic>?,
    );

MediaAsset _$MediaAssetFromJson(Map<String, dynamic> json) => MediaAsset(
      status: json['status'],
      deliveryUrl: json['deliveryUrl'],
      artifactUrl: json['artifactUrl'],
      url: json['url'],
      originalDownloadUrl: json['originalDownloadUrl'],
      variants: json['variants'] == null
          ? const []
          : MediaAssetVariant.listFromJson(json['variants']),
    );

MediaAssetVariant _$MediaAssetVariantFromJson(Map<String, dynamic> json) =>
    MediaAssetVariant(
      deliveryUrl: json['deliveryUrl'],
      artifactUrl: json['artifactUrl'],
      url: json['url'],
      defaultVariant: json['defaultVariant'],
    );
