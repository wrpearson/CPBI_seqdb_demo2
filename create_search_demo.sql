-- used in Basic Protocol 3 to create search_demo mySQL database
DROP DATABASE IF EXISTS search_demo;
CREATE DATABASE search_demo;
GRANT ALL PRIVILEGES ON search_demo.* TO 'seqdb_writer'@'%' IDENTIFIED BY 'writer_pass';
GRANT ALL PRIVILEGES ON search_demo.* TO 'seqdb_reader'@'%' IDENTIFIED BY 'reader_pass';
FLUSH PRIVILEGES;
