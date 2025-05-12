import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert';
import 'utils/encoding_helper.dart';
import 'pages/home_page.dart';
import 'providers/todo_provider.dart';
import 'providers/category_provider.dart';
import 'providers/server_discovery_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/localization_provider.dart';
import 'providers/search_provider.dart';
import 'services/graphql_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize UTF-8 encoding
  EncodingHelper.initialize();
  
  // Create and initialize the GraphQLService before the app starts
  final graphQLService = GraphQLService();
  
  // Explicitly ensure initialization is complete
  await graphQLService.ensureInitialized();
  
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
        // Provide GraphQLService as a value first so it's available to other providers
        Provider.value(value: graphQLService),
        
        // Pass the GraphQLService instance to TodoProvider
        ChangeNotifierProvider(create: (_) => TodoProvider(graphQLService)),
        
        // Pass the GraphQLService instance to CategoryProvider 
        ChangeNotifierProvider(create: (_) => CategoryProvider(graphQLService)),
        
        ChangeNotifierProvider(
          create: (_) => ServerDiscoveryProvider(graphQLService),
        ),
        
        // Add theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Add localization provider
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        
        // Add search provider
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: Consumer2<ThemeProvider, LocalizationProvider>(
        builder: (context, themeProvider, localizationProvider, _) {
          return MaterialApp(
        title: 'Todo List',
        debugShowCheckedModeBanner: false,
            
            // Set the theme mode from provider
            themeMode: themeProvider.themeMode,
            
            // Configure light theme
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.notoSansTextTheme(),
        ),
            
            // Configure dark theme
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                primary: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.notoSansTextTheme(
                ThemeData.dark().textTheme,
              ),
            ),
            
            // Set locale from provider
            locale: localizationProvider.locale,
            
            // Add supported locales
            supportedLocales: localizationProvider.supportedLocales,
            
            // Configure localization delegates
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            
        home: const HomePage(),
          );
        },
      ),
    );
  }
}
