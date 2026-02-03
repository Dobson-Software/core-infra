import { useState } from 'react';
import { Card, Button, InputGroup, Tag, HTMLSelect, Icon } from '@blueprintjs/core';
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { servicesApi } from '../api';

export function ServicesPage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [tierFilter, setTierFilter] = useState('');
  const [teamFilter, setTeamFilter] = useState('');

  const { data: services, isLoading } = useQuery({
    queryKey: ['services', { tier: tierFilter, team: teamFilter }],
    queryFn: () =>
      servicesApi.getServices({
        tier: tierFilter || undefined,
        team: teamFilter || undefined,
      }),
  });

  const filteredServices = (services?.data || []).filter(
    (s) =>
      s.name.toLowerCase().includes(search.toLowerCase()) ||
      s.displayName.toLowerCase().includes(search.toLowerCase())
  );

  const tierIntent = (tier: string) => {
    switch (tier) {
      case 'critical':
        return 'danger';
      case 'standard':
        return 'primary';
      case 'experimental':
        return 'none';
      default:
        return 'none';
    }
  };

  return (
    <div>
      <div className="page-header">
        <h1>Service Catalog</h1>
        <Button intent="primary" icon="plus" text="Add Service" />
      </div>

      {/* Filters */}
      <div
        style={{
          display: 'flex',
          gap: 12,
          marginBottom: 24,
        }}
      >
        <InputGroup
          leftIcon="search"
          placeholder="Search services..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ width: 300 }}
        />
        <HTMLSelect
          value={tierFilter}
          onChange={(e) => setTierFilter(e.target.value)}
        >
          <option value="">All Tiers</option>
          <option value="critical">Critical</option>
          <option value="standard">Standard</option>
          <option value="experimental">Experimental</option>
        </HTMLSelect>
        <HTMLSelect
          value={teamFilter}
          onChange={(e) => setTeamFilter(e.target.value)}
        >
          <option value="">All Teams</option>
          <option value="platform">Platform</option>
          <option value="core">Core</option>
          <option value="integrations">Integrations</option>
        </HTMLSelect>
      </div>

      {/* Service Grid */}
      {isLoading ? (
        <div style={{ textAlign: 'center', padding: 48, color: '#a7b6c2' }}>
          Loading services...
        </div>
      ) : (
        <div className="card-grid">
          {filteredServices.map((service) => (
            <Card
              key={service.id}
              interactive
              onClick={() => navigate(`/services/${service.id}`)}
              style={{ padding: 20 }}
            >
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'flex-start',
                  marginBottom: 12,
                }}
              >
                <div>
                  <h3 style={{ margin: 0, fontSize: 16 }}>{service.displayName}</h3>
                  <code style={{ color: '#a7b6c2', fontSize: 12 }}>{service.name}</code>
                </div>
                <Tag intent={tierIntent(service.tier)} minimal>
                  {service.tier}
                </Tag>
              </div>

              <p
                style={{
                  color: '#a7b6c2',
                  fontSize: 14,
                  margin: '0 0 16px',
                  lineHeight: 1.5,
                }}
              >
                {service.description || 'No description'}
              </p>

              <div
                style={{
                  display: 'flex',
                  gap: 12,
                  fontSize: 12,
                  color: '#a7b6c2',
                }}
              >
                <span>
                  <Icon icon="code" size={12} style={{ marginRight: 4 }} />
                  {service.language || 'N/A'}
                </span>
                <span>
                  <Icon icon="people" size={12} style={{ marginRight: 4 }} />
                  {service.team || 'N/A'}
                </span>
                {service.repository && (
                  <span>
                    <Icon icon="git-branch" size={12} style={{ marginRight: 4 }} />
                    {service.repository.split('/').pop()}
                  </span>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}

      {!isLoading && filteredServices.length === 0 && (
        <Card style={{ textAlign: 'center', padding: 48 }}>
          <Icon icon="search" size={48} style={{ color: '#5c7080', marginBottom: 16 }} />
          <h3 style={{ margin: '0 0 8px' }}>No services found</h3>
          <p style={{ color: '#a7b6c2', margin: 0 }}>
            Try adjusting your search or filters.
          </p>
        </Card>
      )}
    </div>
  );
}
