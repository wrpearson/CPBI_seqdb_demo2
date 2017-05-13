-- used in Basic Protocol 1 to create seqdb_demo mySQL database
DROP DATABASE IF EXISTS seqdb_demo;
CREATE DATABASE seqdb_demo;
GRANT ALL PRIVILEGES ON seqdb_demo.* TO 'seqdb_writer'@'%' IDENTIFIED BY 'writer_pass';
GRANT ALL PRIVILEGES ON seqdb_demo.* TO 'seqdb_reader'@'%' IDENTIFIED BY 'reader_pass';
FLUSH PRIVILEGES;
