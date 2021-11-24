import 'package:f_logs/f_logs.dart';

class Event {
  final String name;

  const Event({required this.name});
}

class EventListener {
  final String eventName; // Evento da seguire (in seguito potrei fare un enum)
  final Function function; // Funzione da chiamare una volta triggerato l'evento

  const EventListener({required this.eventName, required this.function});
}

class EventManager {
  EventManager._internal();

  static final _instance = EventManager._internal();

  List<EventListener> listeners = List.empty(growable: true);

  static EventManager getInstance() => _instance;

  void addListener(EventListener listener) => listeners.add(listener);

  Future<void> dispatchEvent(Event event) async {
    FLog.info(text: "Dispatching event ${event.name}");
    // Serve a controllare se un evento è stato gestito
    // in caso negativo lo aggiungo ad una lista di "vecchi eventi"
    for (var listener in listeners) {
      // Non mi fermo al primo listener per ovvie ragioni
      if (event.name == listener.eventName) {
        // Controllo veloce per vedere se
        // il listener "ascolta" l'evento triggerato
        try {
          listener.function();
        } catch (e, trace) {
          FLog.severe(text: "Error for event ${event.name}", exception: e);
          FLog.trace(text: "Trace", exception: e, stacktrace: trace);
        }
      } // Forse dovrei aggiungere qualcosa di più come controllo,
    } // tipo se viene gestito l'evento ricevuto o meno
  }
}
