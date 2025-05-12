import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Helper method to get current instance from BuildContext
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Static delegate for the localization
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Add all translated strings as getters here
  String get appTitle => _localizedValues[locale.languageCode]?['appTitle'] ?? 'Todo List';
  String get today => _localizedValues[locale.languageCode]?['today'] ?? 'Today';
  String get upcoming => _localizedValues[locale.languageCode]?['upcoming'] ?? 'Upcoming';
  String get all => _localizedValues[locale.languageCode]?['all'] ?? 'All';
  String get completed => _localizedValues[locale.languageCode]?['completed'] ?? 'Completed';
  String get categories => _localizedValues[locale.languageCode]?['categories'] ?? 'Categories';
  String get settings => _localizedValues[locale.languageCode]?['settings'] ?? 'Settings';
  String get addTask => _localizedValues[locale.languageCode]?['addTask'] ?? 'Add Task';
  String get title => _localizedValues[locale.languageCode]?['title'] ?? 'Title';
  String get description => _localizedValues[locale.languageCode]?['description'] ?? 'Description';
  String get category => _localizedValues[locale.languageCode]?['category'] ?? 'Category';
  String get noCategory => _localizedValues[locale.languageCode]?['noCategory'] ?? 'No Category';
  String get dueDate => _localizedValues[locale.languageCode]?['dueDate'] ?? 'Due Date';
  String get dueTime => _localizedValues[locale.languageCode]?['dueTime'] ?? 'Due Time';
  String get priority => _localizedValues[locale.languageCode]?['priority'] ?? 'Priority';
  String get high => _localizedValues[locale.languageCode]?['high'] ?? 'High';
  String get medium => _localizedValues[locale.languageCode]?['medium'] ?? 'Medium';
  String get low => _localizedValues[locale.languageCode]?['low'] ?? 'Low';
  String get none => _localizedValues[locale.languageCode]?['none'] ?? 'None';
  String get location => _localizedValues[locale.languageCode]?['location'] ?? 'Location';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Save';
  String get cancel => _localizedValues[locale.languageCode]?['cancel'] ?? 'Cancel';
  String get delete => _localizedValues[locale.languageCode]?['delete'] ?? 'Delete';
  String get edit => _localizedValues[locale.languageCode]?['edit'] ?? 'Edit';
  String get search => _localizedValues[locale.languageCode]?['search'] ?? 'Search';
  String get searchTodos => _localizedValues[locale.languageCode]?['searchTodos'] ?? 'Search todos...';
  String get theme => _localizedValues[locale.languageCode]?['theme'] ?? 'Theme';
  String get darkTheme => _localizedValues[locale.languageCode]?['darkTheme'] ?? 'Dark Theme';
  String get lightTheme => _localizedValues[locale.languageCode]?['lightTheme'] ?? 'Light Theme';
  String get systemTheme => _localizedValues[locale.languageCode]?['systemTheme'] ?? 'System Default';
  String get language => _localizedValues[locale.languageCode]?['language'] ?? 'Language';
  String get english => _localizedValues[locale.languageCode]?['english'] ?? 'English';
  String get chinese => _localizedValues[locale.languageCode]?['chinese'] ?? 'Chinese';
  String get tags => _localizedValues[locale.languageCode]?['tags'] ?? 'Tags';
  String get addTag => _localizedValues[locale.languageCode]?['addTag'] ?? 'Add Tag';
  String get noTags => _localizedValues[locale.languageCode]?['noTags'] ?? 'No tags';
  String get enterTag => _localizedValues[locale.languageCode]?['enterTag'] ?? 'Enter tag';
  String get noResults => _localizedValues[locale.languageCode]?['noResults'] ?? 'No results found';
  String get noTodos => _localizedValues[locale.languageCode]?['noTodos'] ?? 'No todos';
  String get noCategories => _localizedValues[locale.languageCode]?['noCategories'] ?? 'No categories available';
  String get addNewTask => _localizedValues[locale.languageCode]?['addNewTask'] ?? 'Add New Task';
  String get descriptionOptional => _localizedValues[locale.languageCode]?['descriptionOptional'] ?? 'Description (optional)';
  String get locationOptional => _localizedValues[locale.languageCode]?['locationOptional'] ?? 'Location (optional)';
  String get selectDate => _localizedValues[locale.languageCode]?['selectDate'] ?? 'Select Date';
  String get selectTime => _localizedValues[locale.languageCode]?['selectTime'] ?? 'Select Time';
  String get refreshCategories => _localizedValues[locale.languageCode]?['refreshCategories'] ?? 'Refresh Categories';
  String get newCategory => _localizedValues[locale.languageCode]?['newCategory'] ?? 'New Category';
  String get createCategory => _localizedValues[locale.languageCode]?['createCategory'] ?? 'Create';
  String get categoryName => _localizedValues[locale.languageCode]?['categoryName'] ?? 'Category Name';
  String get categoryColor => _localizedValues[locale.languageCode]?['categoryColor'] ?? 'Category Color';
  String get pleaseEnterTitle => _localizedValues[locale.languageCode]?['pleaseEnterTitle'] ?? 'Please enter a title';
  String get loading => _localizedValues[locale.languageCode]?['loading'] ?? 'Loading Todo Lists...';
  String get serverSettings => _localizedValues[locale.languageCode]?['serverSettings'] ?? 'Server Settings';
  String get refreshingData => _localizedValues[locale.languageCode]?['refreshingData'] ?? 'Refreshing data...';
  String get error => _localizedValues[locale.languageCode]?['error'] ?? 'Error';
  String get connectionError => _localizedValues[locale.languageCode]?['connectionError'] ?? 'The app couldn\'t connect to the configured server. Please check your network connection and server status, or configure a different server.';
  String get general => _localizedValues[locale.languageCode]?['general'] ?? 'General';
  String get noCategoriesFound => _localizedValues[locale.languageCode]?['noCategoriesFound'] ?? 'No categories found';
  String get refresh => _localizedValues[locale.languageCode]?['refresh'] ?? 'Refresh';
  String get deleteCategory => _localizedValues[locale.languageCode]?['deleteCategory'] ?? 'Delete Category';
  String get deleteConfirm => _localizedValues[locale.languageCode]?['deleteConfirm'] ?? 'Are you sure you want to delete the category "{name}"? This will not delete the tasks in this category.';
  String get categoryDeleted => _localizedValues[locale.languageCode]?['categoryDeleted'] ?? '{name} category deleted';
  String get deleteFailed => _localizedValues[locale.languageCode]?['deleteFailed'] ?? 'Failed to delete {name}';
  String get tryAgain => _localizedValues[locale.languageCode]?['tryAgain'] ?? 'Try Again';
  String get attemptingReconnect => _localizedValues[locale.languageCode]?['attemptingReconnect'] ?? 'Attempting to reconnect...';
  String get connectedTo => _localizedValues[locale.languageCode]?['connectedTo'] ?? 'Connected to:';
  String get usingDefaultConnection => _localizedValues[locale.languageCode]?['usingDefaultConnection'] ?? 'Using Default Connection';
  String get usingConfiguredServer => _localizedValues[locale.languageCode]?['usingConfiguredServer'] ?? 'Using Configured Server';
  String get serverConfigNeeded => _localizedValues[locale.languageCode]?['serverConfigNeeded'] ?? 'Server Configuration Needed';
  String get serverConfigInfo => _localizedValues[locale.languageCode]?['serverConfigInfo'] ?? 'To use this app, you need to configure a connection to a GraphQL server. You can either:';
  String get serverConfigScan => _localizedValues[locale.languageCode]?['serverConfigScan'] ?? 'Scan for available servers on your network';
  String get serverConfigManual => _localizedValues[locale.languageCode]?['serverConfigManual'] ?? 'Manually add a server using its IP address and port';
  String get serverConfigDev => _localizedValues[locale.languageCode]?['serverConfigDev'] ?? 'Use the built-in development server (if available)';
  String get configureServer => _localizedValues[locale.languageCode]?['configureServer'] ?? 'Configure Server';
  String get tryDefaultConnection => _localizedValues[locale.languageCode]?['tryDefaultConnection'] ?? 'Try Default Connection';
  String get cannotConnectToServer => _localizedValues[locale.languageCode]?['cannotConnectToServer'] ?? 'Cannot connect to server';
  String get serverLimitationWarning => _localizedValues[locale.languageCode]?['serverLimitationWarning'] ?? 'Server limitation: Only supports a single category';

  // Map of localized values for different languages
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Todo List',
      'today': 'Today',
      'upcoming': 'Upcoming',
      'all': 'All',
      'completed': 'Completed',
      'categories': 'Categories',
      'settings': 'Settings',
      'addTask': 'Add Task',
      'title': 'Title',
      'description': 'Description',
      'category': 'Category',
      'noCategory': 'No Category',
      'dueDate': 'Due Date',
      'dueTime': 'Due Time',
      'priority': 'Priority',
      'high': 'High',
      'medium': 'Medium',
      'low': 'Low',
      'none': 'None',
      'location': 'Location',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'searchTodos': 'Search todos...',
      'theme': 'Theme',
      'darkTheme': 'Dark Theme',
      'lightTheme': 'Light Theme',
      'systemTheme': 'System Default',
      'language': 'Language',
      'english': 'English',
      'chinese': 'Chinese',
      'tags': 'Tags',
      'addTag': 'Add Tag',
      'noTags': 'No tags',
      'enterTag': 'Enter tag',
      'noResults': 'No results found',
      'noTodos': 'No todos',
      'noCategories': 'No categories available',
      'addNewTask': 'Add New Task',
      'descriptionOptional': 'Description (optional)',
      'locationOptional': 'Location (optional)',
      'selectDate': 'Select Date',
      'selectTime': 'Select Time',
      'refreshCategories': 'Refresh Categories',
      'newCategory': 'New Category',
      'createCategory': 'Create',
      'categoryName': 'Category Name',
      'categoryColor': 'Category Color',
      'pleaseEnterTitle': 'Please enter a title',
      'loading': 'Loading Todo Lists...',
      'serverSettings': 'Server Settings',
      'refreshingData': 'Refreshing data...',
      'error': 'Error',
      'connectionError': 'The app couldn\'t connect to the configured server. Please check your network connection and server status, or configure a different server.',
      'general': 'General',
      'noCategoriesFound': 'No categories found',
      'refresh': 'Refresh',
      'deleteCategory': 'Delete Category',
      'deleteConfirm': 'Are you sure you want to delete the category "{name}"? This will not delete the tasks in this category.',
      'categoryDeleted': '{name} category deleted',
      'deleteFailed': 'Failed to delete {name}',
      'tryAgain': 'Try Again',
      'attemptingReconnect': 'Attempting to reconnect...',
      'connectedTo': 'Connected to:',
      'usingDefaultConnection': 'Using Default Connection',
      'usingConfiguredServer': 'Using Configured Server',
      'serverConfigNeeded': 'Server Configuration Needed',
      'serverConfigInfo': 'To use this app, you need to configure a connection to a GraphQL server. You can either:',
      'serverConfigScan': 'Scan for available servers on your network',
      'serverConfigManual': 'Manually add a server using its IP address and port',
      'serverConfigDev': 'Use the built-in development server (if available)',
      'configureServer': 'Configure Server',
      'tryDefaultConnection': 'Try Default Connection',
      'cannotConnectToServer': 'Cannot connect to server',
      'serverLimitationWarning': 'Server limitation: Only supports a single category',
    },
    'zh': {
      'appTitle': '待办事项',
      'today': '今天',
      'upcoming': '即将到来',
      'all': '全部',
      'completed': '已完成',
      'categories': '分类',
      'settings': '设置',
      'addTask': '添加任务',
      'title': '标题',
      'description': '描述',
      'category': '分类',
      'noCategory': '无分类',
      'dueDate': '截止日期',
      'dueTime': '截止时间',
      'priority': '优先级',
      'high': '高',
      'medium': '中',
      'low': '低',
      'none': '无',
      'location': '位置',
      'save': '保存',
      'cancel': '取消',
      'delete': '删除',
      'edit': '编辑',
      'search': '搜索',
      'searchTodos': '搜索待办事项...',
      'theme': '主题',
      'darkTheme': '深色主题',
      'lightTheme': '浅色主题',
      'systemTheme': '系统默认',
      'language': '语言',
      'english': '英语',
      'chinese': '中文',
      'tags': '标签',
      'addTag': '添加标签',
      'noTags': '无标签',
      'enterTag': '输入标签',
      'noResults': '未找到结果',
      'noTodos': '无待办事项',
      'noCategories': '没有可用的分类',
      'addNewTask': '添加新任务',
      'descriptionOptional': '描述（可选）',
      'locationOptional': '位置（可选）',
      'selectDate': '选择日期',
      'selectTime': '选择时间',
      'refreshCategories': '刷新分类',
      'newCategory': '新建分类',
      'createCategory': '创建',
      'categoryName': '分类名称',
      'categoryColor': '分类颜色',
      'pleaseEnterTitle': '请输入标题',
      'loading': '加载待办事项...',
      'serverSettings': '服务器设置',
      'refreshingData': '刷新数据中...',
      'error': '错误',
      'connectionError': '应用无法连接到配置的服务器。请检查您的网络连接和服务器状态，或配置其他服务器。',
      'general': '常规',
      'noCategoriesFound': '未找到分类',
      'refresh': '刷新',
      'deleteCategory': '删除分类',
      'deleteConfirm': '确定要删除分类 "{name}" 吗？此操作不会删除该分类中的任务。',
      'categoryDeleted': '{name} 分类已删除',
      'deleteFailed': '删除 {name} 失败',
      'tryAgain': '重试',
      'attemptingReconnect': '正在尝试重新连接...',
      'connectedTo': '已连接到:',
      'usingDefaultConnection': '使用默认连接',
      'usingConfiguredServer': '使用配置的服务器',
      'serverConfigNeeded': '需要服务器配置',
      'serverConfigInfo': '要使用此应用，您需要配置 GraphQL 服务器连接。您可以：',
      'serverConfigScan': '扫描网络上可用的服务器',
      'serverConfigManual': '使用IP地址和端口手动添加服务器',
      'serverConfigDev': '使用内置开发服务器（如果可用）',
      'configureServer': '配置服务器',
      'tryDefaultConnection': '尝试默认连接',
      'cannotConnectToServer': '无法连接到服务器',
      'serverLimitationWarning': '服务器限制：只支持单个分类',
    },
  };
}

// Delegate class for AppLocalizations
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
} 