import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const PrepaPilotApp());

const Color mint = Color(0xFF63C6A1);
const Color navy = Color(0xFF101820);

class PrepaPilotApp extends StatelessWidget {
  const PrepaPilotApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PREPA PILOT', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: mint, brightness: Brightness.dark), scaffoldBackgroundColor: navy, useMaterial3: true, appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white), cardTheme: CardThemeData(color: const Color(0xFF1B2731), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF202D38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
    home: const PilotHome());
}

class PilotHome extends StatefulWidget { const PilotHome({super.key}); @override State<PilotHome> createState()=>_PilotHomeState(); }
class _PilotHomeState extends State<PilotHome> {
  int tab=0; bool loading=true;
  List<Map<String,dynamic>> professors=[], reviews=[], tasks=[];
  DateTime semesterStart=DateTime(2026,11,16), semesterEnd=DateTime(2027,2,28);
  String semesterName='Semestre 1'; double targetAverage=12; Map<String,double> grades={};
  final pages=['Accueil','Professeurs','À revoir','Planning','Semestre'];
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async {final p=await SharedPreferences.getInstance(); setState((){
    professors=_decode(p.getString('professors')); reviews=_decode(p.getString('reviews')); tasks=_decode(p.getString('tasks'));
    semesterStart=DateTime.tryParse(p.getString('semesterStart')??'')??semesterStart; semesterEnd=DateTime.tryParse(p.getString('semesterEnd')??'')??semesterEnd;
    semesterName=p.getString('semesterName')??semesterName; targetAverage=p.getDouble('targetAverage')??targetAverage;
    final g=p.getString('grades'); if(g!=null){try{grades=(jsonDecode(g) as Map).map((k,v)=>MapEntry(k.toString(),(v as num).toDouble()));}catch(_){}}
    loading=false;}); }
  List<Map<String,dynamic>> _decode(String? raw){if(raw==null)return [];try{return (jsonDecode(raw) as List).map((e)=>Map<String,dynamic>.from(e)).toList();}catch(_){return [];}}
  Future<void> _save() async {final p=await SharedPreferences.getInstance(); await p.setString('professors',jsonEncode(professors)); await p.setString('reviews',jsonEncode(reviews)); await p.setString('tasks',jsonEncode(tasks)); await p.setString('semesterStart',semesterStart.toIso8601String()); await p.setString('semesterEnd',semesterEnd.toIso8601String()); await p.setString('semesterName',semesterName); await p.setDouble('targetAverage',targetAverage); await p.setString('grades',jsonEncode(grades));}
  double get semesterProgress {final now=DateTime.now(); final total=semesterEnd.difference(semesterStart).inSeconds; if(total<=0)return 1; return ((now.difference(semesterStart).inSeconds/total).clamp(0,1)).toDouble();}
  List<Map<String,dynamic>> get dueReviews=>reviews.where((r){final d=DateTime.tryParse(r['next']??'')??DateTime.now(); return !d.isAfter(DateTime.now());}).toList();
  List<Map<String,dynamic>> get openTasks=>tasks.where((t)=>t['done']!=true).toList();
  Future<void> addProfessor() async {final result=await showProfessorDialog(context); if(result!=null){professors.add(result);setState((){});await _save();}}
  Future<void> addReview() async {final r=await showReviewDialog(context);if(r!=null){reviews.add(r);setState((){});await _save();}}
  Future<void> addTask() async {final t=await showTaskDialog(context);if(t!=null){tasks.add(t);setState((){});await _save();}}
  Future<void> addGrade() async {final g=await showGradeDialog(context,grades);if(g!=null){grades[g.key]=g.value;setState((){});await _save();}}
  Future<void> completeReview(Map<String,dynamic> r) async {
    final choice=await showDialog<int>(context:context,builder:(c)=>AlertDialog(title:Text('Révision : ${r['title']}'),content:const Text('Comment s’est passée cette révision ?'),actions:[TextButton(onPressed:()=>Navigator.pop(c,0),child:const Text('Pas maîtrisé')),TextButton(onPressed:()=>Navigator.pop(c,1),child:const Text('En progrès')),FilledButton(onPressed:()=>Navigator.pop(c,2),child:const Text('Maîtrisé'))]));
    if(choice==null)return;
    final interval=[1,3,7,14,30];
    int stage=(r['stage']??0) as int;
    if(choice==0){stage=0;}else{stage=(stage+1).clamp(0,4).toInt();}
    r['stage']=stage;
    r['next']=DateTime.now().add(Duration(days:choice==0?1:interval[stage])).toIso8601String();
    if(choice==2){r['stage']=minInt(stage+1,4);}
    setState((){}); await _save();
  }
  int minInt(int a,int b)=>a<b?a:b;
  Future<void> toggleTask(Map<String,dynamic> t) async {t['done']=!(t['done']==true);setState((){});await _save();}
  Future<void> editSemester() async {final result=await showSemesterDialog(context,semesterName,semesterStart,semesterEnd,targetAverage);if(result!=null){semesterName=result.name;semesterStart=result.start;semesterEnd=result.end;targetAverage=result.target;setState((){});await _save();}}
  Future<void> semesterResults() async {final double avg=grades.isEmpty?0.0:grades.values.reduce((a,b)=>a+b)/grades.length; final successful=grades.isNotEmpty&&avg>=targetAverage; await showDialog<void>(context:context,builder:(c)=>AlertDialog(title:Text(successful?'SEMESTRE VALIDÉ !':'Bilan du semestre'),content:Column(mainAxisSize:MainAxisSize.min,children:[if(successful) const Text('🎉',style:TextStyle(fontSize:52)),Text(grades.isEmpty?'Ajoute tes résultats pour calculer ta moyenne.':'Moyenne saisie : ${avg.toStringAsFixed(2)}/20',style:const TextStyle(fontSize:18)),const SizedBox(height:8),Text(successful?'Bravo pour ton travail et ta régularité. Tu peux célébrer cette réussite !':'Fais le point sans te juger : identifie ce qui a fonctionné et ce que tu veux améliorer au prochain semestre.')]),actions:[FilledButton(onPressed:()=>Navigator.pop(c),child:const Text('Continuer'))]));}
  @override Widget build(BuildContext context){if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator())); return Scaffold(appBar:AppBar(title:const Row(children:[Icon(Icons.flight_takeoff,color:mint),SizedBox(width:10),Text('PREPA PILOT',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1.2))]),actions:[IconButton(tooltip:'Paramètres semestre',onPressed:editSemester,icon:const Icon(Icons.tune))]),body:IndexedStack(index:tab,children:[dashboard(),professorPage(),reviewPage(),planningPage(),semesterPage()]),floatingActionButton:tab==1?FloatingActionButton.extended(onPressed:addProfessor,icon:const Icon(Icons.add),label:const Text('Professeur')):tab==2?FloatingActionButton.extended(onPressed:addReview,icon:const Icon(Icons.add),label:const Text('À revoir')):tab==3?FloatingActionButton.extended(onPressed:addTask,icon:const Icon(Icons.add),label:const Text('Tâche')):null,bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const [NavigationDestination(icon:Icon(Icons.dashboard_outlined),label:'Accueil'),NavigationDestination(icon:Icon(Icons.people_alt_outlined),label:'Profs'),NavigationDestination(icon:Icon(Icons.refresh_outlined),label:'À revoir'),NavigationDestination(icon:Icon(Icons.calendar_month_outlined),label:'Planning'),NavigationDestination(icon:Icon(Icons.flag_outlined),label:'Semestre')]) );}
  Widget dashboard()=>ListView(padding:const EdgeInsets.all(16),children:[Text('Bonjour, pilote.',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:4),Text(DateTime.now().toLocal().toString().substring(0,10),style:TextStyle(color:Colors.white.withOpacity(.6))),const SizedBox(height:16),semesterCard(),const SizedBox(height:14),Row(children:[Expanded(child:statCard('Révisions dues',dueReviews.length,Icons.refresh,mint)),const SizedBox(width:10),Expanded(child:statCard('Tâches ouvertes',openTasks.length,Icons.checklist,Colors.orangeAccent))]),const SizedBox(height:18),sectionTitle('Briefing du jour'),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(dueReviews.isEmpty?'Pas de révision en retard.':'${dueReviews.length} révision(s) à traiter aujourd’hui.',style:const TextStyle(fontWeight:FontWeight.w600)),const SizedBox(height:6),Text(openTasks.isEmpty?'Ajoute tes prochaines tâches pour organiser la journée.':'Priorise une tâche et avance étape par étape.',style:TextStyle(color:Colors.white.withOpacity(.65)))]))),const SizedBox(height:18),sectionTitle('À revoir maintenant'),if(dueReviews.isEmpty)emptyHint('Aucun cours à revoir pour l’instant. Ajoute une notion après un cours.'),...dueReviews.take(3).map(reviewTile),const SizedBox(height:18),sectionTitle('Prochaines tâches'),if(openTasks.isEmpty)emptyHint('Ton planning est vide. Ajoute un devoir ou une séance de révision.'),...openTasks.take(4).map(taskTile),const SizedBox(height:24)]);
  Widget semesterCard(){final pct=(semesterProgress*100).round();return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Icon(Icons.flag,color:mint),const SizedBox(width:8),Expanded(child:Text(semesterName,style:const TextStyle(fontWeight:FontWeight.bold))),Text('$pct%',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold,color:mint))]),const SizedBox(height:12),ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:semesterProgress,minHeight:12,backgroundColor:Colors.white12,color:mint)),const SizedBox(height:8),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('Début ${shortDate(semesterStart)}',style:const TextStyle(fontSize:12)),Text('Fin ${shortDate(semesterEnd)}',style:const TextStyle(fontSize:12))]),Text(semesterProgress>=1?'Semestre terminé : renseigne tes résultats !':semesterProgress<0.25?'Début de parcours : installe tes routines.':semesterProgress<0.5?'Tu construis ton rythme. Continue.':semesterProgress<0.8?'Mi-parcours : consolide les acquis.':'Dernière ligne droite : reste régulier.',style:TextStyle(color:Colors.white.withOpacity(.7)),),if(semesterProgress>=1)Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:semesterResults,icon:const Icon(Icons.celebration),label:const Text('Faire le bilan')))])));}
  Widget professorPage()=>ListView(padding:const EdgeInsets.all(16),children:[pageHeading('Professeurs','Comprendre leur pédagogie pour adapter ta stratégie.'),if(professors.isEmpty)emptyHint('Crée la fiche de chaque professeur : style, rythme, exigences et conseils personnels.'),...professors.map((p)=>Card(child:ExpansionTile(leading:CircleAvatar(backgroundColor:mint.withOpacity(.15),child:const Icon(Icons.person,color:mint)),title:Text(p['name']??'Professeur'),subtitle:Text('${p['subject']??'Matière'} • ${p['style']??'Profil à compléter'}'),childrenPadding:const EdgeInsets.all(16),children:[detailLine('Rythme',p['pace']),detailLine('Exigence',p['demand']),detailLine('Approche en classe',p['approach']),detailLine('Ma stratégie',p['strategy']),detailLine('Points à surveiller',p['watch']),Row(mainAxisAlignment:MainAxisAlignment.end,children:[TextButton(onPressed:()async{final updated=await showProfessorDialog(context,initial:p);if(updated!=null){final ix=professors.indexOf(p);if(ix>=0)professors[ix]=updated;setState((){});await _save();}},child:const Text('Modifier')),TextButton(onPressed:()async{professors.remove(p);setState((){});await _save();},child:const Text('Supprimer'))])])))]);
  Widget reviewPage()=>ListView(padding:const EdgeInsets.all(16),children:[pageHeading('Cours à revoir','Répétition espacée : rappel actif, puis intervalle progressif.'),if(reviews.isEmpty)emptyHint('Ajoute les notions qui restent floues. Elles seront reprogrammées automatiquement après chaque bilan.'),...reviews.map(reviewTile)]);
  Widget planningPage()=>ListView(padding:const EdgeInsets.all(16),children:[pageHeading('Planning','Liste simple de tâches et séances. Coche au fur et à mesure.'),if(tasks.isEmpty)emptyHint('Ajoute devoirs, révisions, préparation de cours ou échéances.'),...tasks.map(taskTile)]);

  // ✅ CORRIGÉ : le ternaire "cond ? a : ...b" est remplacé par if / else dans la liste
  Widget semesterPage() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      pageHeading('Semestre', 'La progression temporelle et tes résultats sont séparés.'),
      semesterCard(),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle('Résultats saisis'),
              if (grades.isEmpty)
                const Text('Aucune note renseignée.')
              else
                ...grades.entries.map(
                  (e) => ListTile(
                    title: Text(e.key),
                    trailing: Text('${e.value.toStringAsFixed(1)}/20'),
                  ),
                ),
              const Divider(),
              Text('Objectif de moyenne : ${targetAverage.toStringAsFixed(1)}/20'),
              Text(
                'Moyenne actuelle : ${grades.isEmpty ? '—' : (grades.values.reduce((a, b) => a + b) / grades.length).toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(onPressed: addGrade, icon: const Icon(Icons.add), label: const Text('Ajouter une note')),
                  OutlinedButton.icon(onPressed: editSemester, icon: const Icon(Icons.edit), label: const Text('Dates & objectif')),
                  OutlinedButton.icon(onPressed: semesterResults, icon: const Icon(Icons.celebration), label: const Text('Bilan')),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      emptyHint('À la fin du semestre, renseigne tes notes. PREPA PILOT compare la moyenne à ton objectif et célèbre la réussite, ou t’aide à faire un bilan utile.'),
    ],
  );

  Widget pageHeading(String title,String subtitle)=>Padding(padding:const EdgeInsets.only(bottom:14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:4),Text(subtitle,style:TextStyle(color:Colors.white.withOpacity(.65)))]));
  Widget sectionTitle(String title)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)));
  Widget statCard(String label,int count,IconData icon,Color color)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:color),const SizedBox(height:8),Text('$count',style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold)),Text(label,style:TextStyle(color:Colors.white.withOpacity(.65)))])));
  Widget emptyHint(String text)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Text(text,style:TextStyle(color:Colors.white.withOpacity(.65)))));
  Widget reviewTile(Map<String,dynamic> r)=>Card(child:ListTile(leading:const Icon(Icons.menu_book,color:mint),title:Text(r['title']??'Notion'),subtitle:Text('${r['subject']??'Matière'} • ${r['kind']??'À revoir'} • ${r['difficulty']??'Moyen'}'),trailing:IconButton(tooltip:'Réviser et noter',icon:const Icon(Icons.play_circle_outline),onPressed:()=>completeReview(r)),onTap:()=>completeReview(r)));
  Widget taskTile(Map<String,dynamic> t)=>Card(child:CheckboxListTile(value:t['done']==true,onChanged:(_)=>toggleTask(t),title:Text(t['title']??'Tâche',style:TextStyle(decoration:t['done']==true?TextDecoration.lineThrough:null)),subtitle:Text('${t['subject']??'Général'}${t['date']!=null?' • ${t['date']}':''}'),secondary:const Icon(Icons.event_note)));
  static Widget detailLine(String label,dynamic value)=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(width:112,child:Text(label,style:const TextStyle(color:mint))),Expanded(child:Text((value==null||value.toString().isEmpty)?'Non renseigné':value.toString()))]));
}
String shortDate(DateTime d)=>'${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

Future<Map<String,dynamic>?> showProfessorDialog(BuildContext context,{Map<String,dynamic>? initial}) async {final name=TextEditingController(text:initial?['name']??''),subject=TextEditingController(text:initial?['subject']??''),style=TextEditingController(text:initial?['style']??''),pace=TextEditingController(text:initial?['pace']??''),demand=TextEditingController(text:initial?['demand']??''),approach=TextEditingController(text:initial?['approach']??''),strategy=TextEditingController(text:initial?['strategy']??''),watch=TextEditingController(text:initial?['watch']??'');return showDialog(context:context,builder:(c)=>AlertDialog(title:Text(initial==null?'Nouveau professeur':'Modifier le professeur'),content:SizedBox(width:420,child:SingleChildScrollView(child:Column(children:[field(name,'Nom'),field(subject,'Matière'),field(style,'Style pédagogique (observé)'),field(pace,'Rythme'),field(demand,'Niveau d’exigence'),field(approach,'Approche en classe'),field(strategy,'Ma stratégie avec lui'),field(watch,'Points à surveiller')]))),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annuler')),FilledButton(onPressed:()=>Navigator.pop(c,{'name':name.text,'subject':subject.text,'style':style.text,'pace':pace.text,'demand':demand.text,'approach':approach.text,'strategy':strategy.text,'watch':watch.text}),child:const Text('Enregistrer'))]));}
Future<Map<String,dynamic>?> showReviewDialog(BuildContext context) async {final title=TextEditingController(),subject=TextEditingController(),note=TextEditingController();String kind='Compréhension',difficulty='Moyen';return showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('Ajouter une notion à revoir'),content:SizedBox(width:420,child:SingleChildScrollView(child:Column(children:[field(title,'Notion / cours'),field(subject,'Matière'),DropdownButtonFormField<String>(value:kind,items:['Compréhension','Exercice','Formule','Mémorisation','Question'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>kind=v??kind,decoration:const InputDecoration(labelText:'Type')),DropdownButtonFormField<String>(value:difficulty,items:['Facile','Moyen','Difficile'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>difficulty=v??difficulty,decoration:const InputDecoration(labelText:'Difficulté')),field(note,'Ce que je dois revoir',lines:3)]))),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annuler')),FilledButton(onPressed:()=>Navigator.pop(c,{'title':title.text,'subject':subject.text,'kind':kind,'difficulty':difficulty,'note':note.text,'stage':0,'next':DateTime.now().toIso8601String()}),child:const Text('Créer'))]));}
Future<Map<String,dynamic>?> showTaskDialog(BuildContext context) async {
  final title=TextEditingController(), subject=TextEditingController();
  DateTime? date;
  return showDialog(context:context,builder:(c)=>AlertDialog(
    title:const Text('Nouvelle tâche'),
    content:SizedBox(width:420,child:Column(mainAxisSize:MainAxisSize.min,children:[
      field(title,'Tâche / devoir'), field(subject,'Matière ou catégorie'),
      StatefulBuilder(builder:(ctx,setLocal)=>ListTile(
        title:Text(date==null?'Date (optionnel)':shortDate(date!)),
        trailing:const Icon(Icons.date_range),
        onTap:()async{final d=await showDatePicker(context:c,initialDate:DateTime.now(),firstDate:DateTime(2025),lastDate:DateTime(2035));if(d!=null)setLocal(()=>date=d);},
      )),
    ])),
    actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annuler')),
      FilledButton(onPressed:()=>Navigator.pop(c,{'title':title.text,'subject':subject.text,'date':date==null?null:shortDate(date!),'done':false}),child:const Text('Ajouter'))]
  ));
}
class SemesterData {final String name;final DateTime start,end;final double target;SemesterData(this.name,this.start,this.end,this.target);}
Future<SemesterData?> showSemesterDialog(BuildContext context,String current,DateTime start,DateTime end,double target) async {
  final name=TextEditingController(text:current), targetCtl=TextEditingController(text:target.toString());
  return showDialog(context:context,builder:(c)=>AlertDialog(
    title:const Text('Configurer le semestre'),
    content:SizedBox(width:420,child:Column(mainAxisSize:MainAxisSize.min,children:[
      field(name,'Nom du semestre'),field(targetCtl,'Objectif de moyenne /20',type:TextInputType.number),
      StatefulBuilder(builder:(ctx,setLocal)=>ListTile(
        title:Text('Début : ${shortDate(start)}'),trailing:const Icon(Icons.date_range),
        onTap:()async{final d=await showDatePicker(context:c,initialDate:start,firstDate:DateTime(2020),lastDate:DateTime(2035));if(d!=null)setLocal(()=>start=d);},
      )),
      StatefulBuilder(builder:(ctx,setLocal)=>ListTile(
        title:Text('Fin : ${shortDate(end)}'),trailing:const Icon(Icons.date_range),
        onTap:()async{final d=await showDatePicker(context:c,initialDate:end,firstDate:DateTime(2020),lastDate:DateTime(2035));if(d!=null)setLocal(()=>end=d);},
      )),
    ])),
    actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annuler')),FilledButton(onPressed:()=>Navigator.pop(c,SemesterData(name.text,start,end,double.tryParse(targetCtl.text.replaceAll(',','.'))??target)),child:const Text('Enregistrer'))]
  ));
}
Future<MapEntry<String,double>?> showGradeDialog(BuildContext context,Map<String,double> existing) async {final subject=TextEditingController(),score=TextEditingController();return showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('Ajouter un résultat'),content:Column(mainAxisSize:MainAxisSize.min,children:[field(subject,'Matière'),field(score,'Note sur 20',type:TextInputType.number)]),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annuler')),FilledButton(onPressed:()=>Navigator.pop(c,MapEntry(subject.text,double.tryParse(score.text.replaceAll(',','.'))??0.0)),child:const Text('Ajouter'))]));}
Widget field(TextEditingController controller,String label,{int lines=1,TextInputType type=TextInputType.text})=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:TextField(controller:controller,maxLines:lines,keyboardType:type,decoration:InputDecoration(labelText:label)));
