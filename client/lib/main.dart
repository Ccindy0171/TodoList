import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'providers/todo_provider.dart';
import 'providers/category_provider.dart';
import 'providers/server_discovery_provider.dart';
import 'services/graphql_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create and initialize the GraphQLService before the app starts
  final graphQLService = GraphQLService();
  // Wait for initialization to complete
  await Future.delayed(Duration(milliseconds: 500));
  
  // Print the server URL that will be used
  print('? Main: Starting app with GraphQL server: ${graphQLService.serverUrl}');
  print('? Main: Is using default URL: ${graphQLService.isUsingDefaultUrl}');
  print('? Main: Allow default URL: ${graphQLService.allowDefaultUrl}');
  
  runApp(MyApp(graphQLService: graphQLService));
}

class MyApp extends StatelessWidget {
  final GraphQLService graphQLService;
  
  const MyApp({super.key, required this.graphQLService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(
          create: (_) => ServerDiscoveryProvider(graphQLService),
        ),
        // Provide GraphQLService as a value
        Provider.value(value: graphQLService),
      ],
      child: MaterialApp(
        title: 'Todo List',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.notoSansTextTheme(),
        ),
        home: const HomePage(),
      ),
    );
  }
}
