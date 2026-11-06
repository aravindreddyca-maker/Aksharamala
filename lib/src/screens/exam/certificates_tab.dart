import 'package:flutter/material.dart';

import '../../exam/models.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'exam_scope.dart';
import 'exam_widgets.dart';

/// Section (d): certificates, one per level.
class CertificatesTab extends StatelessWidget {
  const CertificatesTab({required this.child, super.key});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final exams = ExamScope.of(context);
    final certs = exams.certificatesFor(child.id)
      ..sort((a, b) => a.level.compareTo(b.level));
    return PageBody(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (certs.isEmpty)
            const Notice(
              'No certificates yet. One is issued when a Final Level '
              'Examination is passed (and every writing item is marked).',
              key: Key('no_certificates'),
            ),
          for (final c in certs)
            Card(
              child: ListTile(
                key: Key('certificate_${c.level}'),
                minTileHeight: 64,
                leading: const Icon(Icons.workspace_premium_rounded),
                title: Text('Level ${c.level} certificate'),
                subtitle: Text('${formatDate(c.issuedAt)}  ${c.id}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        CertificateScreen(childId: child.id, level: c.level),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CertificateScreen extends StatelessWidget {
  const CertificateScreen(
      {required this.childId, required this.level, super.key});

  final String childId;
  final int level;

  Future<void> _reissue(BuildContext context) async {
    final exams = ExamScope.of(context);
    final ok = await confirmDialog(
      context,
      title: 'Reissue this certificate?',
      message: 'The same certificate is shown again with a reissue count. '
          'No second certificate is made.',
      confirmLabel: 'Reissue',
      confirmKey: const Key('confirm_reissue'),
    );
    if (ok) await exams.reissueCertificate(childId, level);
  }

  @override
  Widget build(BuildContext context) {
    final cert = ExamScope.of(context).certificateFor(childId, level);
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Certificate'),
        backgroundColor: Colors.transparent,
      ),
      child: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (cert == null)
              const Notice('This certificate could not be found.')
            else ...[
              _CertificateCard(cert: cert),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('reissue_certificate'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(GameTokens.minTouch)),
                onPressed: () => _reissue(context),
                child: const Text('Reissue certificate'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.cert});

  final Certificate cert;

  @override
  Widget build(BuildContext context) {
    final name = cert.displayName;
    return Semantics(
      container: true,
      label:
          'Certificate. ${cert.statement} Issued ${formatDate(cert.issuedAt)}. '
          'Number ${cert.id}.',
      child: ExcludeSemantics(
        child: Container(
          key: const Key('certificate_card'),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEA),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFC9A227), width: 4),
          ),
          child: Column(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  size: 56, color: Color(0xFFC9A227)),
              Text('Certificate of Completion',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              const Text('This certifies that'),
              Text(name,
                  key: const Key('certificate_name'),
                  textAlign: TextAlign.center,
                  style: scriptStyle(
                      name,
                      Theme.of(context).textTheme.headlineMedium ??
                          const TextStyle())),
              const SizedBox(height: 6),
              Text('completed Level ${cert.level} in Aksharamala.',
                  key: const Key('certificate_level'),
                  textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Text('Date: ${formatDate(cert.issuedAt)}',
                  key: const Key('certificate_date'),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Certificate number: ${cert.id}',
                    key: const Key('certificate_id'),
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center),
              ),
              if (cert.issuedCount > 1)
                Text('Reissued ${cert.issuedCount - 1} time(s)',
                    key: const Key('certificate_reissued')),
              const SizedBox(height: 10),
              const Text(
                'Awarded by the Aksharamala app after a parent-run exam. '
                'It is a family keepsake and not an accredited qualification.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
