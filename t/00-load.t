use utf8;
use strict;
use warnings;
use Test::More;

{

    use_ok 'Validation::Class::Deep';

}

{

    package TC1;

    use Validation::Class::Deep;

    field  'id'     => { filters => ['numeric'], min_length => 1, required => 1 };

    package main;

    my $class = TC1->new;

    ok "TC1" eq ref $class, "TC1 instantiated";

    can_ok $class, "id";

    $class->id('ABC');

    ok !$class->validate('id'), "TC1 ID field could not be validated";

}

{

    package TC2;

    use Validation::Class::Deep;

    field  'title';
    field  'rating';
    field  'name';

    field  'id' => { filters => ['numeric'] };

    domain 'person' => {
        'id'                                   => 'id',
        'name'                                 => 'name',
        'title'                                => 'title',
        'company.name'                         => 'name',
        'company.supervisor.name'              => 'name',
        'company.supervisor.rating.@.support'  => 'rating',
        'company.supervisor.rating.@.guidance' => 'rating',
        'company.tags.@'                       => 'name'
    };

    package main;

    my $class;

    eval { $class = TC2->new; };

    ok "TC2" eq ref $class, "TC2 instantiated";

    my $domains = $class->prototype->settings->get('domains');

    ok "Validation::Class::Mapping" eq ref $domains, "TC2 domains registered as setting";

    ok 1 == $domains->count, "TC2 has 1 registered domain";

    my $person = $domains->get('person');

    ok 8 == keys %{$person}, "TC2 person domain has 6 mappings";

    can_ok $class, 'validate_domain';

    $person = {
        "id"      => "1234-ABC",
        "name"    => "Anita Campbell-Green",
        "title"   => "Designer",
        "company" => {
            "name"       => "House of de Vil",
            "supervisor" => {
                "name"   => "Cruella de Vil",
                "rating" => [
                    {   "support"  => -9,
                        "guidance" => -9
                    }
                ]
            },
            "tags" => [
                "evil",
                "cruelty",
                "dogs"
            ]
        },
    };

    ok $class->validate_domain(person => $person), "TC2 domain (person) validated";
    ok $person->{id} !~ /\D/, "person document has been filtered";

}

{

    package TC3;

    use Validation::Class::Deep;

    field  'title';
    field  'rating';
    field  'name';
    field  'id';

    domain 'company' => {
        'company.name'                  => 'name',
        'company.supervisor.name'       => 'name',
        'company.supervisor.rating.@.*' => 'rating',
        'company.tags.@'                => 'name'
    };

    package main;

    my $class;

    eval { $class = TC3->new; };

    ok "TC3" eq ref $class, "TC3 instantiated";

    my $person = {
        "id"      => "1234-ABC",
        "name"    => "Anita Campbell-Green",
        "title"   => "Designer",
        "company" => {
            "name"       => "House of de Vil",
            "supervisor" => {
                "name"   => "Cruella de Vil",
                "rating" => [
                    {   "support"  => -9,
                        "guidance" => -9
                    }
                ]
            },
            "tags" => [
                "evil",
                "cruelty",
                "dogs"
            ]
        },
    };

    ok $class->validate_domain(company => $person), "TC3 domain (company) validated";

}

{

    package TC4;

    use Validation::Class::Deep;

    field  'id' => {
        mixin      => [':str'],
        filters    => ['numeric'],
        max_length => 2,
    };

    field  'name' => {
        mixin      => [':str'],
        pattern    => qr/^[A-Za-z ]+$/,
        max_length => 20,
    };

    field  'tag' => {
        mixin      => [':str'],
        pattern    => qr/^(?!evil)\w+/,
        max_length => 20,
    };

    domain 'company' => {
        'id'                            => 'id',
        'company.name'                  => 'name',
        'company.supervisor.name'       => 'name',
        'company.tags.@'                => 'tag'
    };

    package main;

    my $class;

    eval { $class = TC4->new(ignore_unknown => 1); };

    ok "TC4" eq ref $class, "TC4 instantiated";

    my $person = {
        "id"      => "1234-ABC",
        "name"    => "Anita Campbell-Green",
        "title"   => "Designer",
        "company" => {
            "name"       => "House of de Vil",
            "supervisor" => {
                "name"   => "Cruella de Vil",
                "rating" => [
                    {   "support"  => -9,
                        "guidance" => -9
                    }
                ]
            },
            "tags" => [
                "evil",
                "cruelty",
                "dogs"
            ]
        },
    };

    ok !$class->validate_domain(company => $person), "TC4 domain (company) did not validate";

}

done_testing;
