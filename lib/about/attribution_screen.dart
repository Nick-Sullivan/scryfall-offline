import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AttributionScreen extends StatelessWidget {
  const AttributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Attribution', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'All card data and card images are copyright © Wizards of the '
            'Coast, LLC, and are provided by Scryfall.\n\n'
            'This app is unofficial Fan Content permitted under the Wizards '
            'of the Coast Fan Content Policy. It is not published, endorsed, '
            'or approved by Wizards of the Coast or Scryfall.\n\n'
            'Card data and search are free in this app and always will be.',
          ),
          const SizedBox(height: 16),
          _link(context, 'Scryfall', 'https://scryfall.com'),
          _link(context, 'Fan Content Policy',
              'https://company.wizards.com/en/legal/fancontentpolicy'),
          const Divider(height: 32),
          Text('Open source', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'The search syntax implementation is informed by CubeCobra\'s '
            'open-source filter grammar (Apache License 2.0).',
          ),
          const SizedBox(height: 8),
          _link(context, 'CubeCobra on GitHub',
              'https://github.com/dekkerglen/CubeCobra'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'Scryfall Offline Search',
            ),
            child: const Text('Third-party licenses'),
          ),
        ],
      ),
    );
  }

  Widget _link(BuildContext context, String label, String url) {
    return TextButton.icon(
      style: TextButton.styleFrom(alignment: Alignment.centerLeft),
      onPressed: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text(label),
    );
  }
}
