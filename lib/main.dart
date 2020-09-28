import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class ForeignExchange {
  final Map<String, dynamic> rates;
  final String base;
  final String date;

  ForeignExchange({this.rates, this.base, this.date});

  factory ForeignExchange.fromJson(Map<String, dynamic> json) {
    return ForeignExchange(
      rates: json['rates'] as Map<String, dynamic>,
      base: json['base'] as String,
      date: json['date'] as String,
    );
  }
}

Future<ForeignExchange> fetchResponse() async {
  final response = await http.get('https://api.exchangeratesapi.io/latest');

  if (response.statusCode == 200) {
    return ForeignExchange.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load');
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ForeignExchangeRate(),
    );
  }
}

class ForeignExchangeRate extends StatefulWidget {
  @override
  _ForeignExchangeRateState createState() => _ForeignExchangeRateState();
}

class _ForeignExchangeRateState extends State<ForeignExchangeRate> {
  Future<ForeignExchange> futureForeignExchange;
  String title = "loading..";
  String updated = "loading..";
  int currency;
  TextEditingController controller = TextEditingController();
  bool reload = false;

  @override
  void initState() {
    super.initState();
    futureForeignExchange = fetchResponse();
    futureForeignExchange.then((value) {
      setState(() {
        title = value.base;
        updated = value.date;
      });
    });
    currency = 1;
    controller.text = "1";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                reload = true;
                title = "loading..";
                updated = "loading..";
              });
              Future.delayed(const Duration(seconds: 1), () {
                setState(() {
                  futureForeignExchange = fetchResponse();
                  futureForeignExchange.then((value) {
                    setState(() {
                      title = value.base;
                      updated = value.date;
                      reload = false;
                    });
                  });
                });
              });
            },
            icon: Icon(Icons.refresh),
          ),
        ],
        title: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            Text(
              "last Refreshed :$updated",
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
      body: reload == true
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    controller: controller,
                    keyboardType: TextInputType.number,
                    // onChanged: (value) {
                    //   setState(() {
                    //     currency = int.parse(controller.text);
                    //   });
                    // },
                  ),
                ),
                SizedBox(height: 20),
                FlatButton(
                  padding: EdgeInsets.all(10),
                  color: Colors.blue,
                  onPressed: () {
                    setState(() {
                      currency = int.parse(controller.text);
                    });
                  },
                  child: Text(
                    "Convert",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                FutureBuilder<ForeignExchange>(
                  future: futureForeignExchange,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      Map<String, double> rateMap =
                          Map.from(snapshot.data.rates);
                      var keysList = rateMap.keys.toList();
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: ListView.builder(
                            itemCount: snapshot.data.rates.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  keysList[index],
                                  style: TextStyle(fontSize: 20),
                                ),
                                subtitle: Text(
                                  '${currency * rateMap[keysList[index]]}',
                                  style: TextStyle(fontSize: 15),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text(snapshot.error.toString());
                    }
                    return Center(child: CircularProgressIndicator());
                  },
                ),
              ],
            ),
    );
  }
}
