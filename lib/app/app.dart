import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../features/activities/presentation/pages/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ثبت فعالیت‌ها',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomePage(),
    );
  }
}
