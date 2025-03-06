import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Main entry point for the application.
/// Sets up landscape orientation before launching the app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Force landscape orientation for better carousel display
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MyApp());
  });
}

/// Root application widget that sets up the MaterialApp with theme settings.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animated Profile Slider',
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
      home: const SimpleAnimatedList(),
    );
  }
}

/// Wrapper widget that creates a Scaffold with the main SliceAnimatedList.
class SimpleAnimatedList extends StatelessWidget {
  const SimpleAnimatedList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SliceAnimatedList());
  }
}

/// Main animated carousel component that displays items in a horizontal row
/// with the selected item centered and scaled up.
class SliceAnimatedList extends StatefulWidget {
  const SliceAnimatedList({super.key});

  @override
  _SliceAnimatedListState createState() => _SliceAnimatedListState();
}

class _SliceAnimatedListState extends State<SliceAnimatedList>
    with TickerProviderStateMixin {
  // Constants for animations and layout
  static const double _ITEM_WIDTH = 150.0;
  static const double _ITEM_SPACING = 180.0;
  static const double _MAX_SCALE = 1.0;
  static const double _MIN_SCALE = 0.3;
  static const double _SCALE_FACTOR = 0.2;
  static const Duration _ANIMATION_DURATION = Duration(milliseconds: 300);
  static const Duration _BUTTON_PULSE_DURATION = Duration(milliseconds: 1500);

  // Item data and state
  final List<int> _items = [];
  int _counter = 0;
  int _selectedIndex = 2; // Default selected item (middle of initial 5 items)

  // Button animation controller
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize the carousel with 5 items
    _populateInitialItems();

    // Setup button animation controller for pulsing effect
    _initializeButtonAnimation();
  }

  /// Populates initial items in the carousel
  void _populateInitialItems() {
    for (int i = 0; i < 5; i++) {
      _items.add(_counter++);
    }
  }

  /// Initializes the animation for the navigation buttons
  void _initializeButtonAnimation() {
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: _BUTTON_PULSE_DURATION,
    )..repeat(reverse: true);

    _buttonAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  /// Updates the selected item index and triggers animation
  void _selectItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Navigates to the previous item if not at the beginning
  void _selectPreviousItem() {
    if (_selectedIndex > 0) {
      _selectItem(_selectedIndex - 1);
    }
  }

  /// Navigates to the next item if not at the end
  void _selectNextItem() {
    if (_selectedIndex < _items.length - 1) {
      _selectItem(_selectedIndex + 1);
    }
  }

  /// Builds an individual card item for the carousel
  Widget buildCardItem(
    BuildContext context,
    int item,
    TextStyle? textStyle,
    double scale,
  ) {
    return SizedBox(
      width: _ITEM_WIDTH,
      child: Card(
        color: Colors.primaries[item % Colors.primaries.length],
        child: Center(child: Text('Item $item', style: textStyle)),
      ),
    );
  }

  /// Calculates the scale for an item based on its distance from the selected item
  double _calculateItemScale(int index) {
    final int distanceFromCenter = (index - _selectedIndex).abs();
    return (_MAX_SCALE - (distanceFromCenter * _SCALE_FACTOR)).clamp(
      _MIN_SCALE,
      _MAX_SCALE,
    );
  }

  /// Builds a carousel item with position and scale animations
  Widget _buildCarouselItem(BuildContext context, int index) {
    final double scale = _calculateItemScale(index);
    final double offsetX = (index - _selectedIndex) * _ITEM_SPACING;

    TextStyle? textStyle = Theme.of(context).textTheme.headlineMedium;
    int item = _items[index];

    return AnimatedPositioned(
      duration: _ANIMATION_DURATION,
      curve: Curves.easeInOut,
      left: MediaQuery.of(context).size.width / 2 - _ITEM_WIDTH / 2 + offsetX,
      child: GestureDetector(
        onTap: () => _selectItem(index),
        child: AnimatedScale(
          scale: scale,
          duration: _ANIMATION_DURATION,
          curve: Curves.easeInOut,
          child: buildCardItem(context, item, textStyle, scale),
        ),
      ),
    );
  }

  /// Builds a navigation button with pulse animation
  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isLeft,
  }) {
    return AnimatedBuilder(
      animation: _buttonAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonAnimation.value,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(icon, color: Colors.white),
              onPressed: onPressed,
              iconSize: 30,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 150.0,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Generate all carousel items
              ...List.generate(
                _items.length,
                (index) => _buildCarouselItem(context, index),
              ),

              // Left navigation button - only show if not at first item
              if (_selectedIndex > 0)
                Positioned(
                  left: 20,
                  child: _buildNavigationButton(
                    icon: Icons.arrow_back_ios,
                    onPressed: _selectPreviousItem,
                    isLeft: true,
                  ),
                ),

              // Right navigation button - only show if not at last item
              if (_selectedIndex < _items.length - 1)
                Positioned(
                  right: 20,
                  child: _buildNavigationButton(
                    icon: Icons.arrow_forward_ios,
                    onPressed: _selectNextItem,
                    isLeft: false,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
