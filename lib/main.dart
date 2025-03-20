import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_model.dart';
import "secrets.dart";


void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Hava Durumu'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> cities = [
    "Ankara",
    "İstanbul",
    "İzmir",
    "Bursa",
    "Eskişehir",
    "Muğla",
    "Bolu",
    "Trabzon",
    "Samsun",
    "Antalya"
  ];

  String? secilenSehir;
  Future<WeatherModel>? weatherFuture;
  final TextEditingController _searchController = TextEditingController();
  List<String> filteredCities = [];

  @override
  void initState() {
    super.initState();
    filteredCities = List.from(cities); // Başlangıçta tüm şehirleri göster
  }

  void selectedCity(String cityName) {
    setState(() {
      secilenSehir = cityName;
      weatherFuture = getWeather(cityName);
      // Arama alanını temizle
      _searchController.clear();
      // Filtrelenmiş şehirleri sıfırla
      filteredCities = List.from(cities);
    });
    // Seçilen şehri GridView'da bul ve kaydır
    _scrollToSelectedCity(cityName);
  }

  final dio = Dio(BaseOptions(
    baseUrl: Secrets.baseUrl,
    queryParameters: {
      "appid": Secrets.apiKey,
      "lang": "tr",
      "units": "metric"
    },
  ));

  Future<WeatherModel> getWeather(String selectedCity) async {
    final response =
    await dio.get("/weather", queryParameters: {"q": selectedCity});
    var model = WeatherModel.fromJson(response.data);
    debugPrint(model.name);
    return model;
  }

  Widget _buildWeatherCard(WeatherModel weatherModel) {
    return Card(
      color: Colors.lightGreenAccent,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(weatherModel.name!,
                style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(
              height: 8,
            ),
            Text(
              "${weatherModel.main!.temp!.round()}°",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              weatherModel.weather![0].description ?? "Değer yok!",
              style: TextStyle(fontSize: 17),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Icon(Icons.water_drop),
                    Text(
                      "%${weatherModel.main!.humidity!.round()}",
                      style: TextStyle(fontSize: 17),
                    )
                  ],
                ),
                SizedBox(
                  width: 60,
                ),
                Column(
                  children: [
                    Icon(Icons.air_outlined),
                    Text(
                      "${weatherModel.wind!.speed!.round()} m/s",
                      style: TextStyle(fontSize: 17),
                    )
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollToSelectedCity(String cityName) {
    if (_scrollController.hasClients) {
      final index = cities.indexOf(cityName);
      if (index != -1) {
        final itemHeight = 100.0; // Her bir Card'ın yaklaşık yüksekliği
        final rowCount = 2; // GridView'in sütun sayısı
        final itemIndex = index;
        final row = itemIndex ~/ rowCount;
        final targetOffset = row * (itemHeight + 16); // Card yüksekliği + aralık
        _scrollController.animateTo(
          targetOffset,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _filterCities(String query) {
    setState(() {
      filteredCities = cities
          .where((city) => city.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Şehir Ara'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Şehir Adı',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: _filterCities,
                          onSubmitted: (value) {
                            if (filteredCities.isNotEmpty) {
                              selectedCity(filteredCities.first);
                              Navigator.pop(context); // Dialog'u kapat
                            }
                          },
                        ),
                        SizedBox(height: 16),
                        if (_searchController.text.isNotEmpty && filteredCities.isEmpty)
                          Text('Aradığınız şehir bulunamadı.'),
                        if (_searchController.text.isNotEmpty && filteredCities.isNotEmpty)
                          SizedBox(
                            width: double.maxFinite,
                            height: 150,
                            child: ListView.builder(
                              itemCount: filteredCities.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(filteredCities[index]),
                                  onTap: () {
                                    selectedCity(filteredCities[index]);
                                    Navigator.pop(context); // Dialog'u kapat
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Kapat'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Dialog'u kapat
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (weatherFuture != null)
            FutureBuilder(
              future: weatherFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                }
                if (snapshot.hasData) {
                  return _buildWeatherCard(snapshot.data!);
                }
                return const SizedBox();
              },
            ),
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.5),
              itemBuilder: (context, index) {
                if (index < filteredCities.length) {
                  final cityName = filteredCities[index];
                  final isSelected = secilenSehir == cityName;
                  return GestureDetector(
                    onTap: () => selectedCity(cityName),
                    child: Card(
                      color: isSelected ? Colors.lightGreen : Colors.blue,
                      child: Center(
                        child: Text(cityName,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              itemCount: filteredCities.length,
            ),
          )
        ],
      ),
    );
  }
}