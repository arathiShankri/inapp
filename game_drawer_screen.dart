 /// this is the method that is called when the user clicks on "remove ads" in the drawer.
 /// this method will invove the corresponding "purchaseRemoveAds" method in InAppRepo.
 
 Widget _drawRemoveAdsMenu(BuildContext context) => GestureDetector(
      onTap: () {
        Navigator.pop(context);
        InAppModule().get<InAppRepo>().purchaseRemoveAds();
      },
      child: _drawerTile(
        context,
        Icons.attach_money,
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).removeAds,
                style: TextStyle(
                  fontSize: super.getTextTheme(context).subtitle1.fontSize,
                )),
          ],
        ),
        AppLocalizations.of(context).removeAds,
        usePrimaryIconColor: true,
      ));
