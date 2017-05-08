-- used in Basic Protocol 3 to create search_demo mySQL database
CREATE DATABASE search_demo;
GRANT ALL PRIVILEGES ON search_demo.* TO 'seqdb_writer'@'%' IDENTIFIED BY 'writer_pass';
GRANT ALL PRIVILEGES ON search_demo.* TO 'seqdb_reader'@'%' IDENTIFIED BY 'reader_pass';
FLUSH PRIVILEGES;
