<?php

abstract class WrPgObject extends PgObject
{
    protected $schema = 'wasserrecht';
    protected $tableName = null;
    protected $write_debug = true;
    
    function WrPgObject($gui) {
        parent::__construct($gui, $this->schema, $this->tableName);
    }
    
    public function find_by_id($gui, $by, $id) {
        return $this->find_by_id_with_className(get_called_class(), $gui, $by, $id);
    }
    
    public function find_by_id_with_className($className, $gui, $by, $id) {
        $object = new $className($gui);
        $object->find_by($by, $id);
        return $object;
    }
    
    public function getName() {
        return $this->data['name'];
    }
    
    public function getId() {
        return $this->data['id'];
    }
    
    public function toString() {
        return "id: " . $this->getId() . " name: " . $this->getName();
    }
}