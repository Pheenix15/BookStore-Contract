// add new books
// get book statues ,
// update book statues : number in shelve
// remove book

#[derive(Copy, Drop, Serde, starknet::Store)]
struct Book {
    title: felt252,
    author: felt252,
    genre: felt252,
    in_shelf: u16,
}

#[starknet::interface]
pub trait IBookStore<TContractState> {
    fn add_book(
        ref self: TContractState,
        book_id: felt252,
        title: felt252,
        author: felt252,
        genre: felt252,
        in_shelf: u16
    );
    fn update_book_status(ref self: TContractState, book_id: felt252, num_in_shelf: u16);
    fn get_book(self: @TContractState, book_id: felt252) -> Book;
}


#[starknet::contract]
pub mod BookStore {
    use super::{Book, IBookStore};
    use core::starknet::{
        get_caller_address, ContractAddress,
        storage::{Map, StorageMapReadAccess, StorageMapWriteAccess}
    };

    #[storage]
    struct Storage {
        // map book Id to book struct
        books: Map<felt252, Book>,
        librarian_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BookAdded: BookAdded,
        BookUpdated: BookUpdated
    }

    #[derive(Drop, starknet::Event)]
    struct BookAdded {
        book_id: felt252,
        title: felt252,
        author: felt252,
        genre: felt252,
        in_shelf: u16
    }

    #[derive(Drop, starknet::Event)]
    struct BookUpdated {
        book_id: felt252,
        num_in_shelf: u16
    }

    #[constructor]
    fn constructor(ref self: ContractState, librarian_address: ContractAddress) {
        self.librarian_address.write(librarian_address)
    }

    #[abi(embed_v0)]
    impl BookstoreImpl of IBookStore<ContractState> {
        fn add_book(
            ref self: ContractState,
            book_id: felt252,
            title: felt252,
            author: felt252,
            genre: felt252,
            in_shelf: u16
        ) {
            let librarian_address = self.librarian_address.read();
            assert(get_caller_address() == librarian_address, 'You are not a librarian');

            let book = Book { title: title, author: author, genre: genre, in_shelf: in_shelf };

            self.books.write(book_id, book);

            self.emit(BookAdded { book_id, title, author, genre, in_shelf })
        }

        fn update_book_status(ref self: ContractState, book_id: felt252, num_in_shelf: u16) {
            let librarian_address = self.librarian_address.read();

            assert(get_caller_address() == librarian_address, 'You are not a librarian');

            let mut book = self.books.read(book_id);
            book.in_shelf = num_in_shelf;
            self.books.write(book_id, book);

            self.emit(BookUpdated { book_id, num_in_shelf })
        }

        fn get_book(self: @ContractState, book_id: felt252) -> Book {
            self.books.read(book_id)
        }
    }
}

