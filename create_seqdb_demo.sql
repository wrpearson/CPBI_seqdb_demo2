-- used in Basic Protocol 1 to create seqdb_demo mySQL database
CREATE DATABASE seqdb_demo;
GRANT ALL PRIVILEGES ON seqdb_demo.* TO 'seqdb_writer'@'%' IDENTIFIED BY 'writer_pass';
GRANT ALL PRIVILEGES ON seqdb_demo.* TO 'seqdb_reader'@'%' IDENTIFIED BY 'reader_pass';
FLUSH PRIVILEGES;
