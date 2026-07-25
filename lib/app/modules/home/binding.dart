import 'package:get/get.dart';

import '../../../services/places.dart';
import '../../data/repository/storage_repository.dart';
import 'controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StorageRepository>(() => StorageRepository(), fenix: true);
    Get.lazyPut<PlacesProvider>(() => PlacesProvider(), fenix: true);

    Get.lazyPut<HomeController>(
          () => HomeController(
        placesProvider: Get.find<PlacesProvider>(),
        repository: Get.find<StorageRepository>(),
      ),
    );
  }
}