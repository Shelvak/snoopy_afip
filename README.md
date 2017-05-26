# snoopy_afip
conexión con Web Service de Factura Electrónica de AFIP (WSFE)

## Instalación

Añadir esta linea en el Gemfile:

```ruby
gem 'snoopy_afip'
```

Luego ejecuta:

    $ bundle

O instala la gema a mano:

    $ gem install snoopy_afip

## Antes que nada

Link con el manual para desarrolladores

http://wswhomo.afip.gov.ar/fiscaldocs/WSAA/Especificacion_Tecnica_WSAA_1.2.0.pdf

Es recomendable descargar los wsdl para evitar tener que pedirlo en cada request

https://wswhomo.afip.gov.ar/wsfev1/service.asmx?wsdl  Para entorno de desarrollo
https://servicios1.afip.gov.ar/wsfev1/service.asmx?WSDL Para entorno de producción

## Uso

### Inicialización de parametros generales

```ruby
Snoopy.default_moneda    = :peso
Snoopy.default_concepto  = 'Servicios'
Snoopy.default_documento = 'CUIT'
# Para el caso de produccion
Snoopy.auth_url    = "https://wsaa.afip.gov.ar/ws/services/LoginCms" 
Snoopy.service_url = "prod.wsdl"
# Para el caso de desarrollo
Snoopy.auth_url    = "https://wsaahomo.afip.gov.ar/ws/services/LoginCms"
Snoopy.service_url = "testing.wsdl"
```

En caso de trabajar con `Ruby on Rails`, es recomendable crear un archivo con esta conf en `config/initializers`.

### Generar Clave privada
```ruby
Snoopy::AuthData.generate_pkey(tmp_pkey_path)
```
Donde `tmp_pkey_path` es la ruta donde se quiere que se guarde la pkey.

### Generar solicitud de pedido de certificado

```ruby
Snoopy::AuthData.generate_certificate_request(pkey_path, subj_o, subj_cn, subj_cuit, certificate_request_path)
```

* `pkey_path`: Ruta absoluta de la llave privada.
* `subj_o`: Nombre de la compañia.
* `subj_cn`: # Hostname del server que generar las solicitudesm en ruby se obtiene con %x(hostname).chomp
* `subj_cuit`: # Cuit registrado en la AFIP de la compañia que emita facturas.
* `certificate_request_path`: Ruta donde queres que se guarde el pedido de certificado.

Una vez generado este archivo debe hacerse el tramite en el sitio web de la AFIP para obtener el certificado que les permitirá emitir facturas al webservice.

<!-- Snoopy::AuthData.generate_auth_file(data) -->

<!-- data[:pkey] pkey_path, -->
<!-- data[:cert]          certificate_path, -->
<!-- data[:taxpayer]cuit: taxpayer_identification_number, -->
<!--           sale_point: sale_point, -->
<!--           own_iva_cond: vat_condition == ArgentinaResponsableMonotributo ? :responsable_monotributo : :responsable_inscripto -->

### Verficar comunicación con servicio

Por medio del siguiente comando es posible verificar si la comunicación con el webservice de la AFIP se establecio de manera correcta.

```ruby
Snoopy::AuthData.generate_auth_file(data)
```

* `data[:pkey]`         # PATH de la clave privada (Utilizada para generar el pedido del certificado).
* `data[:cert]`         # PATH del certificado otorgado por la AFIP.
* `data[:cuit]`         # CUIT del emisor de la factura.
* `data[:sale_point]`   # Punto de venta del emisor de la factura.
* `data[:own_iva_cond]` # Condición de iva del emiso de factura. [:responsable_monotributo : :responsable_inscripto]

### Informar factura
Siempre para informar una factura debe de definirse un hash con los siguientes key, value:

* `attrs[:pkey]`                # path de la clave privada (Utilizada para generar el pedido del certificado).
* `attrs[:cert]`                # path del certificado otorgado por la afip.
* `attrs[:cuit]`                # CUIT del emisor de la factura.
* `attrs[:sale_point]`          # Punto de venta del emisor de la factura.
* `attrs[:own_iva_cond]`        # Condición de iva del emisor de la factura
* `attrs[:net]`                 # Monto neto por defecto es 0
* `attrs[:documento]`           # Tipo de documento a utilizar, por default Snoopy.default_documento ["CUIT" "DNI" "Doc. (Otro)"]
* `attrs[:moneda]`              # Tipo de moneda a utilizar por default Snoopy.default_moneda
* `attrs[:concepto]`            # Concepto de la factura por defecto Snoopy.default_concepto
* `attrs[:doc_num]`             # Numero de documento
* `attrs[:fch_serv_desde]`      # Inicio de vigencia de la factura
* `attrs[:fch_serv_hasta]`      # Fin de vigencia de la factura
* `attrs[:cbte_asoc_pto_venta]` # Esto es el punto de venta de la factura para la nota de crédito (Solo pasar si se esta creando una nota de crédito)
* `attrs[:cbte_asoc_num]`       # Esto es el numero de factura para la nota de crédito (Solo pasar si se esta creando una nota de crédito)
* `attrs[:iva_cond]`            # Condición de iva
* `attrs[:imp_iva]`             # Monto total de impuestos
* `attrs[:alicivas]`            # Impuestos asociados a la factura

El `attrs[:alicivas]` discrimina la información de los items. Es posible que en la factura se discrimine diferentes items con diferentes impuestos. Para ello el `attrs[:alicivas]` es un arreglo de hashes. Donde cada uno de ellos contenga la información sobre un determinado impuesto.

```ruby
{ id:       tax_rate.round_with_precision(2),    # Porcentaje. Ej: "0.105", "0.21", "0.27"
  importe:  tax_amount.round_with_precision(2),  # Monto total del item.
  base_imp: net_amount.round_with_precision(2) } # Monto de base imponible.
```

Por ejemplo si se tiene 5 items, donde 3 de ellos tienen un impuesto del 10.5% y los 2 restantes del 21%. Los primeros 3 deben, se debera de crear dos hashes de la siguientes forma.

```ruby
attrs[:alicivas] [ { id: (10.5 / 100 ).to_s 
                     importe: X,            # De los 3 items 10.5
                     base_imp: Y },
                   { id: (21 / 100 ).to_s 
                     importe: X,            # De los 2 items de 21
                     base_imp: Y } ]
```
Donde: 

* `X`: Es la suma total de los items que corresponda.
* `Y`: Base imponible de la suma de los items que corresponda.

Los `tax_rates` soportados por AFIP son los siguientes:

```ruby
Snoopy::ALIC_IVA
```

#### Tips:

La base imponible se calcula de la siguiente manera:

```ruby
total_amount / (1 + tax_percentage)
```

Finalmente para informar la factura a AFIP simplemente:

```ruby
bill = Snoopy::Bill.new(attr) # construyo el objeto bill.
bill.cae_request # Informo Afip la factura.
```

### Resultado obtenido desde la Afip

Una vez llamado al metodo `cae_request` podemos verificar el resultado en el objeto bill.

```ruby
bill.aprobada? # Salio todo bien en la AFIP con la factura informada.
bill.parcial? # Aprobada parcialmente.
bill.rechazada? # Rechazada algo esta mal.
bill.response # Respuesta completa de AFIP.
bill.errors # Errores generados dentro de la gema o  entregados por la AFIP.
bill.observaciones # Observaciones entregadas por la AFIP.
bill.events # Eventos entregados por la AFIP.
bill.backtrace # En caso de ocurrir un error dentro de la gema.
```
## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
