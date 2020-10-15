import 'dart:async';
import 'dart:io';

import '../../credits/credits_screen.dart';

import '../../app_constants.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../appsettings/settings_barrel.dart';
import '../../core/utils/logging.dart';
import '../../game/game_barrel.dart';

class InAppRepo {
  final SettingsRepo _settingsRepo;
  final GameProvider _gameProvider;

  // this is the product Id as created for the consumable on app connect and google play
  static String _removeAdId = 'remove_ads';
  final Set<String> _productIds = <String>{_removeAdId};

  StreamSubscription _subscription;

  InAppRepo(this._gameProvider, this._settingsRepo) {
    if (!AppConstants.mockInAppPurchaseForTesting) {
      _enablePurchaseUpdatedStreamSubscription();
    }
  }

  Future<void> _enablePurchaseUpdatedStreamSubscription() async {
    if (!await this._settingsRepo.isAdFreeVersion()) {
      _subscription = InAppPurchaseConnection.instance.purchaseUpdatedStream.listen((data) async {
        if (data.isNotEmpty) {
          //only item sold is 'add free version' ... no consumables
          PurchaseDetails purchaseDetails = data.firstWhere((purchase) => purchase.productID == _removeAdId);

          // only for iOS
          if (purchaseDetails == null && Platform.isIOS) {
            await InAppPurchaseConnection.instance.refreshPurchaseVerificationData();
          }

          if (purchaseDetails.status != null) {
            switch (purchaseDetails.status) {
              case PurchaseStatus.purchased:
                Platform.isIOS ? InAppPurchaseConnection.instance.completePurchase(purchaseDetails) : InAppPurchaseConnection.instance.consumePurchase(purchaseDetails);
                await _enableAdFreeOnPurchaseOrRestore(GamePurchasedStatus.Purchased);
                break;
              case PurchaseStatus.error:
                CreditsScreen.inApppurchaseError =
                    'code: ${purchaseDetails.error.code}, details: ${purchaseDetails.error.details}, message: ${purchaseDetails.error.message}, ';
                _gameProvider.setJustPurchased(GamePurchasedStatus.Error);
                _gameProvider.initNewGame(notify: true);
                break;
              case PurchaseStatus.pending:
                print('purchase pending');
                break;
            }
          }
        }
      }, onDone: () {
        _subscription.cancel();
      }, onError: (error) {
        Logger().warn(
          classNm: 'InAppRepo',
          methodNm: '_errorOnListeningToPurchases',
          message: '_errorOnListeningToPurchases: error $error',
          categoryName: LogCategory.other,
        );
      });
    }
  }

  /// purchase remove ads
  void purchaseRemoveAds() async {
    if (AppConstants.mockInAppPurchaseForTesting) {
      await _enableAdFreeOnPurchaseOrRestore(GamePurchasedStatus.Purchased);
      return;
    }
    //user will now buy the product
    List<ProductDetails> availableProducts = await _getAvailableProducts();
    if (availableProducts.isNotEmpty) {
      ProductDetails productDetails = availableProducts.firstWhere((productDetail) => productDetail.id == _removeAdId);
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails, sandboxTesting: !AppConstants.isProduction);
      await InAppPurchaseConnection.instance.isAvailable();
      InAppPurchaseConnection.instance.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  ///called on dispose of main
  Future disablePurchaseUpdatedStreamSubscription() => _subscription?.cancel();

  /// restore purchase
  void restorePurchase() async {
    List<PurchaseDetails> purchases = await _getPastPurchases();
    bool hasPurchases = false;

    if (purchases.isNotEmpty) {
      PurchaseDetails purchasedProductDetails = purchases.firstWhere((productDetail) => productDetail.productID == _removeAdId);
      //user has already purchased the our product
      if (purchasedProductDetails != null) {
        await _enableAdFreeOnPurchaseOrRestore(GamePurchasedStatus.Restored);
        hasPurchases = true;
      }
    }

    if (!hasPurchases) {
      _gameProvider.setJustPurchased(GamePurchasedStatus.NothingToRestore);
      _gameProvider.initNewGame(notify: true);
    }
  }

  Future<void> _enableAdFreeOnPurchaseOrRestore(GamePurchasedStatus purchasedStatus) async {
    await _settingsRepo.setAdFreeVersion(true);
    _gameProvider.setJustPurchased(purchasedStatus);
    _gameProvider.initNewGame(notify: true);
  }

  /// get products
  Future<List<ProductDetails>> _getAvailableProducts() async {
    ProductDetailsResponse productDetailQueryResponse = await InAppPurchaseConnection.instance.queryProductDetails(_productIds);
    return Future.value(productDetailQueryResponse.error == null ? productDetailQueryResponse.productDetails : <ProductDetails>[]);
  }

  /// get past purchases
  Future<List<PurchaseDetails>> _getPastPurchases() async {
    QueryPurchaseDetailsResponse purchaseDetailsResponse = await InAppPurchaseConnection.instance.queryPastPurchases();
    return Future.value(purchaseDetailsResponse.error == null ? purchaseDetailsResponse.pastPurchases : <PurchaseDetails>[]);
  }

  /*
  Future<void> checkIfPurchased() async {
    if (((await _getPastPurchases()).firstWhere((productDetail) => productDetail.productID == _removeAdId)) == null) {
      await _settingsRepo.setAdFreeVersion(true);
      _gameProvider.initNewGame(notify: true);
    }
  }*/

}
