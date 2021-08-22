part of 'home_screen.dart';

class TodoList extends StatelessWidget {
  const TodoList();
  @override
  Widget build(BuildContext context) {
    return OnReactive(
      () {
        return ListView.builder(
          itemCount: todosFiltered.state.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index <= todosFiltered.state.length - 1) {
              return todos.item.inherited(
                key: Key('${todosFiltered.state[index].id}'),
                item: () {
                  print('${todosFiltered.state.length} ::$index');
                  return todosFiltered.state[index];
                },
                builder: (_) => TodoItem(),
                debugPrintWhenNotifiedPreMessage: 'todo $index',
              );
            } else {
              //Add CircularProgressIndicator on bottom of the list
              //while waiting for adding one item
              return todosFiltered.onOrElse(
                onWaiting: () => Center(child: CircularProgressIndicator()),
                orElse: (_) => Container(),
              );
            }
          },
        );
      },
    );
  }
}
