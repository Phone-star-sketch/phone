


mixin CrudOperations <T> {

    Future<Object> create(T item);
    Future<T> read(Object id); 
    Future<void> update(T item); 
    Future<void> delete(T item); 
     
}