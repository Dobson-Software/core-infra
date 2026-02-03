import { useState } from 'react';
import { Card, HTMLSelect, Tag, HTMLTable, Icon } from '@blueprintjs/core';
import { useQuery } from '@tanstack/react-query';
import { costsApi } from '../api';
import {
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import { format, subDays } from 'date-fns';

const COLORS = ['#6366f1', '#8b5cf6', '#a855f7', '#d946ef', '#ec4899'];

export function CostsPage() {
  const [environment, setEnvironment] = useState('');
  const [dateRange, setDateRange] = useState('30');

  const startDate = format(subDays(new Date(), parseInt(dateRange)), 'yyyy-MM-dd');
  const endDate = format(new Date(), 'yyyy-MM-dd');

  const { data: costSummary } = useQuery({
    queryKey: ['costs', 'summary', { startDate, endDate, environment }],
    queryFn: () =>
      costsApi.getCostSummary({
        startDate,
        endDate,
        environment: environment || undefined,
      }),
  });

  const { data: costTrend } = useQuery({
    queryKey: ['costs', 'trend', { startDate, endDate }],
    queryFn: () =>
      costsApi.getCostTrend({
        startDate,
        endDate,
        granularity: 'daily',
      }),
  });

  const totalCost = (costSummary?.data || []).reduce(
    (sum, env) => sum + env.totalCost,
    0
  );

  const previousCost = (costSummary?.data || []).reduce(
    (sum, env) => sum + env.previousPeriodCost,
    0
  );

  const changePercent =
    previousCost > 0 ? ((totalCost - previousCost) / previousCost) * 100 : 0;

  // Mock data for by-resource chart
  const resourceData = [
    { name: 'EC2', cost: 4500 },
    { name: 'RDS', cost: 2800 },
    { name: 'S3', cost: 800 },
    { name: 'Lambda', cost: 450 },
    { name: 'Other', cost: 650 },
  ];

  return (
    <div>
      <div className="page-header">
        <h1>Cost Explorer</h1>
        <div style={{ display: 'flex', gap: 12 }}>
          <HTMLSelect
            value={environment}
            onChange={(e) => setEnvironment(e.target.value)}
          >
            <option value="">All Environments</option>
            <option value="production">Production</option>
            <option value="staging">Staging</option>
            <option value="development">Development</option>
          </HTMLSelect>
          <HTMLSelect
            value={dateRange}
            onChange={(e) => setDateRange(e.target.value)}
          >
            <option value="7">Last 7 Days</option>
            <option value="30">Last 30 Days</option>
            <option value="90">Last 90 Days</option>
          </HTMLSelect>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="card-grid" style={{ marginBottom: 24 }}>
        <Card className="stat-card">
          <div className="stat-value">${(totalCost / 1000).toFixed(2)}k</div>
          <div className="stat-label">Total Spend ({dateRange} days)</div>
          <Tag
            intent={changePercent > 0 ? 'danger' : 'success'}
            minimal
            style={{ marginTop: 8 }}
          >
            {changePercent > 0 ? '+' : ''}
            {changePercent.toFixed(1)}% vs previous period
          </Tag>
        </Card>

        <Card className="stat-card">
          <div className="stat-value">
            ${(totalCost / parseInt(dateRange)).toFixed(0)}
          </div>
          <div className="stat-label">Average Daily Spend</div>
        </Card>

        <Card className="stat-card">
          <div className="stat-value">
            ${((totalCost / parseInt(dateRange)) * 30).toFixed(0)}
          </div>
          <div className="stat-label">Projected Monthly</div>
        </Card>
      </div>

      {/* Charts Row */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: '2fr 1fr',
          gap: 24,
          marginBottom: 24,
        }}
      >
        {/* Trend Chart */}
        <Card>
          <h3 style={{ margin: '0 0 16px' }}>Cost Trend</h3>
          <div style={{ height: 300 }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={costTrend?.data || []}>
                <CartesianGrid strokeDasharray="3 3" stroke="#383e47" />
                <XAxis
                  dataKey="date"
                  stroke="#a7b6c2"
                  tickFormatter={(date) => format(new Date(date), 'MMM d')}
                />
                <YAxis
                  stroke="#a7b6c2"
                  tickFormatter={(val) => `$${val}`}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#252a31',
                    border: '1px solid #383e47',
                  }}
                  formatter={(value: number) => [`$${value.toFixed(2)}`, 'Cost']}
                />
                <Area
                  type="monotone"
                  dataKey="cost"
                  stroke="#6366f1"
                  fill="url(#colorCost)"
                  strokeWidth={2}
                />
                <defs>
                  <linearGradient id="colorCost" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                  </linearGradient>
                </defs>
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        {/* By Resource Type */}
        <Card>
          <h3 style={{ margin: '0 0 16px' }}>By Resource Type</h3>
          <div style={{ height: 300 }}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={resourceData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={2}
                  dataKey="cost"
                  nameKey="name"
                  label={({ name, percent }) =>
                    `${name} ${(percent * 100).toFixed(0)}%`
                  }
                  labelLine={false}
                >
                  {resourceData.map((_, index) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={COLORS[index % COLORS.length]}
                    />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#252a31',
                    border: '1px solid #383e47',
                  }}
                  formatter={(value: number) => [`$${value.toFixed(2)}`, 'Cost']}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      {/* By Environment */}
      <Card style={{ marginBottom: 24 }}>
        <h3 style={{ margin: '0 0 16px' }}>Cost by Environment</h3>
        <div style={{ height: 200 }}>
          <ResponsiveContainer width="100%" height="100%">
            <BarChart
              data={costSummary?.data || []}
              layout="vertical"
              margin={{ left: 80 }}
            >
              <CartesianGrid strokeDasharray="3 3" stroke="#383e47" />
              <XAxis
                type="number"
                stroke="#a7b6c2"
                tickFormatter={(val) => `$${val}`}
              />
              <YAxis
                type="category"
                dataKey="environment"
                stroke="#a7b6c2"
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: '#252a31',
                  border: '1px solid #383e47',
                }}
                formatter={(value: number) => [`$${value.toFixed(2)}`, 'Cost']}
              />
              <Bar dataKey="totalCost" fill="#6366f1" radius={[0, 4, 4, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </Card>

      {/* Top Services Table */}
      <Card>
        <h3 style={{ margin: '0 0 16px' }}>Top Services by Cost</h3>
        <HTMLTable bordered condensed style={{ width: '100%' }}>
          <thead>
            <tr>
              <th>Service</th>
              <th>Environment</th>
              <th>Cost</th>
              <th>Change</th>
            </tr>
          </thead>
          <tbody>
            {(costSummary?.data || [])
              .flatMap((env) =>
                env.topServices.map((svc) => ({
                  ...svc,
                  environment: env.environment,
                }))
              )
              .sort((a, b) => b.cost - a.cost)
              .slice(0, 10)
              .map((svc, i) => (
                <tr key={i}>
                  <td>{svc.serviceName}</td>
                  <td>
                    <Tag minimal>{svc.environment}</Tag>
                  </td>
                  <td>${svc.cost.toFixed(2)}</td>
                  <td>
                    <Icon icon="arrow-up" size={12} style={{ color: '#f85149' }} />
                    <span style={{ marginLeft: 4 }}>+5.2%</span>
                  </td>
                </tr>
              ))}
          </tbody>
        </HTMLTable>
      </Card>
    </div>
  );
}
